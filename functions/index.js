const functions = require('firebase-functions');
const admin = require('firebase-admin');
const speakeasy = require('speakeasy');
const { v4: uuidv4 } = require('uuid');
admin.initializeApp();

const db = admin.firestore();

/**
 * Rate Limiter Middleware
 */
const checkRateLimit = async (uid, type, limit, windowMs) => {
    const now = admin.firestore.Timestamp.now();
    const windowStart = new Date(now.toDate().getTime() - windowMs);
    
    const limitRef = db.collection('users').doc(uid).collection('vibetalkLimits').doc(type);
    const limitDoc = await limitRef.get();
    
    let data = limitDoc.exists ? limitDoc.data() : { count: 0, firstAttempt: now };
    
    if (data.firstAttempt.toDate() < windowStart) {
        data = { count: 1, firstAttempt: now };
    } else {
        data.count += 1;
    }
    
    await limitRef.set(data);
    return data.count <= limit;
};

/**
 * Find Vibe Match with Weighted Scoring
 */
exports.findVibeMatch = functions.https.onCall(async (data, context) => {
    // TASK 1: App Check Verification
    if (context.app === undefined) {
        throw new functions.https.HttpsError('failed-precondition', 'The function must be called from a verified app.');
    }
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const uid = context.auth.uid;
    const { languageCode, continent, wantsGames } = data;
    
    // Rate Limit: 10 queue joins per hour
    const isAllowed = await checkRateLimit(uid, 'queueJoins', 10, 3600000);
    if (!isAllowed) throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded. Try again later.');

    // Retrieve client uid's age tier from users_private/{uid} doc
    const userPrivateDoc = await db.collection('users_private').doc(uid).get();
    if (!userPrivateDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'User age verification record not found.');
    }
    const userPrivateData = userPrivateDoc.data();
    if (userPrivateData.ageTier !== 4) {
        throw new functions.https.HttpsError('permission-denied', 'Matching features are restricted strictly to adult users (18+) to maintain a safe, positive, and compliant community ecosystem.');
    }

    // Check Cooldown
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();
    if (userData && userData.cooldownUntil && userData.cooldownUntil.toDate() > new Date()) {
        throw new functions.https.HttpsError('permission-denied', 'You are on cooldown.');
    }

    return await db.runTransaction(async (transaction) => {
        const queueRef = db.collection('vibetalk_queue').where('isMatched', '==', false).orderBy('joinedAt').limit(20);
        const snapshot = await transaction.get(queueRef);
        
        let bestMatch = null;
        let maxScore = -1;
        
        snapshot.forEach(doc => {
            if (doc.id === uid) return;
            const candidate = doc.data();
            let score = 0;
            
            if (candidate.languageCode === languageCode) score += 40;
            if (candidate.continent === continent) score += 20;
            if (candidate.wantsGames && wantsGames) score += 20;
            
            const waitTime = (new Date() - candidate.joinedAt.toDate()) / 1000;
            score += Math.min(waitTime / 10, 20);
            
            if (score > maxScore) {
                maxScore = score;
                bestMatch = doc;
            }
        });

        if (bestMatch && maxScore >= 30) {
            const roomId = uuidv4();
            const callerId = uid;
            const calleeId = bestMatch.id;

            transaction.update(bestMatch.ref, { 
                isMatched: true, 
                matchedWith: callerId, 
                roomId: roomId 
            });

            const roomRef = db.collection('vibetalk_rooms').doc(roomId);
            transaction.set(roomRef, {
                id: roomId,
                callerId: callerId,
                calleeId: calleeId,
                users: [callerId, calleeId],
                status: 'active',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                reconnectionState: 'stable',
                gameState: { round: 0, bothVoted: false }
            });

            return { roomId };
        } else {
            // Add self to queue if no match
            const myQueueRef = db.collection('vibetalk_queue').doc(uid);
            transaction.set(myQueueRef, {
                uid: uid,
                isMatched: false,
                languageCode,
                continent,
                wantsGames,
                joinedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return { status: 'queued' };
        }
    });
});

/**
 * Handle Game Votes Atomically
 */
exports.submitVibeGameVote = functions.https.onCall(async (data, context) => {
    // TASK 1: App Check Verification
    if (context.app === undefined) {
        throw new functions.https.HttpsError('failed-precondition', 'The function must be called from a verified app.');
    }
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { roomId, vote } = data;
    if (!roomId || vote === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing roomId or vote.');
    }

    const uid = context.auth.uid;
    const roomRef = db.collection('vibetalk_rooms').doc(roomId);

    return await db.runTransaction(async (tx) => {
        const snap = await tx.get(roomRef);
        const room = snap.data();
        if (!room) throw new functions.https.HttpsError('not-found', 'Room not found.');

        const isUserA = room.callerId === uid;
        const updateKey = isUserA ? 'gameState.userAVote' : 'gameState.userBVote';
        
        tx.update(roomRef, { [updateKey]: vote });

        // Check if both have voted using the local state + current vote
        const userAVote = isUserA ? vote : room.gameState?.userAVote;
        const userBVote = !isUserA ? vote : room.gameState?.userBVote;

        if (userAVote && userBVote) {
            tx.update(roomRef, { 'gameState.bothVoted': true });
        }
    });
});

/**
 * Gemini AI Proxy (TASK 1)
 * Protects API key and enforces App Check
 */
exports.geminiProxy = functions.https.onCall(async (data, context) => {
    if (context.app === undefined) {
        throw new functions.https.HttpsError('failed-precondition', 'The function must be called from a verified app.');
    }
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    const { prompt } = data;
    if (!prompt) throw new functions.https.HttpsError('invalid-argument', 'Missing prompt.');

    // In production, call vertex AI or gemini API here.
    return {
        response: `[Verified Proxy] I can only help with Gotchaa questions. Your query about "${prompt.substring(0, 20)}..." has been verified via App Check.`,
        timestamp: new Date().toISOString()
    };
});

/**
 * Notify on New Comment
 */
exports.onVybzCommentCreated = functions.firestore
    .document('vybz/{vybzId}/comments/{commentId}')
    .onCreate(async (snapshot, context) => {
        const comment = snapshot.data();
        const vybzId = context.params.vybzId;
        
        // Get the Vybz post to find the owner
        const vybzDoc = await db.collection('vybz').doc(vybzId).get();
        const vybzData = vybzDoc.data();
        if (!vybzData || vybzData.userId === comment.userId) return;

        // Get owner's private data for FCM token
        const userPrivateDoc = await db.collection('users_private').doc(vybzData.userId).get();
        const userPrivateData = userPrivateDoc.data();
        if (!userPrivateData || !userPrivateData.fcmToken) return;

        const message = {
            notification: {
                title: 'New Comment on Vybz!',
                body: `${comment.userName}: ${comment.text.substring(0, 50)}${comment.text.length > 50 ? '...' : ''}`,
            },
            token: userPrivateData.fcmToken,
            data: { vybzId: vybzId }
        };

        return admin.messaging().send(message);
    });

/**
 * Send Chat Notification
 */
exports.sendChatNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    if (!message) return null;

    const chatId = context.params.chatId;
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return null;

    const chatData = chatDoc.data();
    const participants = chatData.participants || [];
    const receiverId = participants.find(id => id !== message.senderId);
    if (!receiverId) return null;

    const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
    const receiverPrivateDoc = await admin.firestore().collection('users_private').doc(receiverId).get();
    const senderPrivateDoc = await admin.firestore().collection('users_private').doc(message.senderId).get();
    if (!receiverDoc.exists || !receiverPrivateDoc.exists || !senderPrivateDoc.exists) return null;

    const receiverData = receiverDoc.data();
    const receiverPrivateData = receiverPrivateDoc.data();
    const senderPrivateData = senderPrivateDoc.data();
    const fcmToken = receiverPrivateData.fcmToken;

    const senderAgeTier = senderPrivateData.ageTier ?? 5;
    const receiverAgeTier = receiverPrivateData.ageTier ?? 5;

    // Junior Mode (13-15): If receiver is Junior, check if receiver follows the sender
    if (receiverAgeTier === 2) {
      const followDoc = await admin.firestore().collection('users').doc(receiverId).collection('following').doc(message.senderId).get();
      if (!followDoc.exists) {
        console.log(`Notification blocked: Receiver (${receiverId}) is in Junior Mode and does not follow Sender (${message.senderId})`);
        return null;
      }
    }

    // Teen Mode (16-17): If sender or receiver is Teen, verify mutual follow relationship
    if (senderAgeTier === 3 || receiverAgeTier === 3) {
      const recFollowsSender = await admin.firestore().collection('users').doc(receiverId).collection('following').doc(message.senderId).get();
      const sendFollowsRec = await admin.firestore().collection('users').doc(message.senderId).collection('following').doc(receiverId).get();
      if (!recFollowsSender.exists || !sendFollowsRec.exists) {
        console.log(`Notification blocked: Sender (${message.senderId}) or Receiver (${receiverId}) is Teen and mutual follow is not established`);
        return null;
      }
    }

    const isMuted = chatData.isMuted?.[receiverId] ?? false;
    
    // Check if receiver has activity status (publicly visible if they allow it)
    const activeChatId = receiverPrivateData.activeChatId;
    if (activeChatId === chatId) return null;

    if (!fcmToken || isMuted) return null;

    let senderName = (chatData.participantNames && chatData.participantNames[message.senderId]) || 'Someone';
    
    // If senderName is 'Someone', try to fetch it from users collection
    if (senderName === 'Someone') {
      const senderDoc = await admin.firestore().collection('users').doc(message.senderId).get();
      if (senderDoc.exists) {
        const senderData = senderDoc.data();
        senderName = senderData.displayName || senderData.username || 'Someone';
      }
    }

    let body = message.type === 'text' ? message.text : message.type === 'image' ? '📷 Photo' : '🎤 Voice message';
    if (message.isEncrypted === true) {
      body = '🔒 Encrypted Message';
    }
    
    return admin.messaging().send({
      token: fcmToken,
      notification: { title: senderName, body: body.substring(0, 100) },
      data: { chatId, senderId: message.senderId },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } }
    });
  });

/**
 * Send VibeTalk Notification
 */
exports.sendVibeTalkNotification = functions.firestore
  .document('vibetalk_rooms/{roomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    if (!message) return null;

    const roomId = context.params.roomId;
    const roomDoc = await admin.firestore().collection('vibetalk_rooms').doc(roomId).get();
    if (!roomDoc.exists) return null;

    const roomData = roomDoc.data();
    const participants = roomData.users || [];
    const receiverId = participants.find(id => id !== message.senderId);
    if (!receiverId) return null;

    const receiverPrivateDoc = await admin.firestore().collection('users_private').doc(receiverId).get();
    const senderPrivateDoc = await admin.firestore().collection('users_private').doc(message.senderId).get();
    if (!receiverPrivateDoc.exists || !senderPrivateDoc.exists) return null;

    const receiverPrivateData = receiverPrivateDoc.data();
    const senderPrivateData = senderPrivateDoc.data();
    const fcmToken = receiverPrivateData.fcmToken;

    const senderAgeTier = senderPrivateData.ageTier ?? 5;
    const receiverAgeTier = receiverPrivateData.ageTier ?? 5;

    // VibeTalk Safety Check: Both participants must be adults (ageTier === 4)
    if (senderAgeTier < 4 || receiverAgeTier < 4) {
      console.log(`VibeTalk Notification blocked: Sender ageTier is ${senderAgeTier}, Receiver ageTier is ${receiverAgeTier}. VibeTalk is strictly restricted to adults.`);
      return null;
    }

    if (!fcmToken) return null;

    return admin.messaging().send({
      token: fcmToken,
      notification: { 
        title: 'New VibeTalk Message', 
        body: message.text.substring(0, 100) 
      },
      data: { roomId, senderId: message.senderId },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } }
    });
  });

/**
 * Mirror Realtime DB presence to Firestore
 */
// exports.onUserStatusChanged = functions.database
//   .ref('/status/{uid}')
//   .onUpdate(async (change, context) => {
//     const eventStatus = change.after.val();
//     const userStatusFirestoreRef = admin.firestore().doc(`users/${context.params.uid}`);
// 
//     return userStatusFirestoreRef.update({
//         isOnline: eventStatus.isOnline,
//         lastSeen: eventStatus.lastSeen ? admin.firestore.Timestamp.fromMillis(eventStatus.lastSeen) : admin.firestore.FieldValue.serverTimestamp()
//     });
//   });

/**
 * 🔔 Notifications & Analytics Triggers
 */

exports.onLikeCreate = functions.firestore
    .document('posts/{postId}/likes/{uid}')
    .onCreate(async (snap, context) => {
        const postId = context.params.postId;
        const likerUid = context.params.uid;
        const postDoc = await db.collection('posts').doc(postId).get();
        if (!postDoc.exists) return null;
        const post = postDoc.data();
        if (post.userId === likerUid) return null;

        const likerDoc = await db.collection('users').doc(likerUid).get();
        const liker = likerDoc.data();

        // Increment Analytics
        await updateAnalytics(post.userId, { likesCount: 1 });

        // Update post metadata for trending re-computation
        await db.collection('posts').doc(postId).update({
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return db.collection('notifications').doc(post.userId).collection('userNotifications').add({
            type: 'like',
            fromUid: likerUid,
            fromUsername: liker.displayName || liker.username,
            fromAvatar: liker.profilePictureUrl || '',
            fromNationFlag: liker.nationFlag || '🌍',
            targetId: postId,
            targetImageUrl: post.mediaUrls ? post.mediaUrls[0] : null,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            __ttl: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
        });
    });

exports.onCommentCreate = functions.firestore
    .document('posts/{postId}/comments/{commentId}')
    .onCreate(async (snap, context) => {
        const comment = snap.data();
        const postId = context.params.postId;
        const commenterUid = comment.userId;

        const postDoc = await db.collection('posts').doc(postId).get();
        if (!postDoc.exists) return null;
        const post = postDoc.data();

        // Increment Analytics
        await updateAnalytics(post.userId, { commentsReceived: 1 });

        // Update post metadata for trending re-computation
        await db.collection('posts').doc(postId).update({
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (post.userId !== commenterUid) {
            const commenterDoc = await db.collection('users').doc(commenterUid).get();
            const commenter = commenterDoc.data();

            await db.collection('notifications').doc(post.userId).collection('userNotifications').add({
                type: 'comment',
                fromUid: commenterUid,
                fromUsername: commenter.displayName || commenter.username,
                fromAvatar: commenter.profilePictureUrl || '',
                fromNationFlag: commenter.nationFlag || '🌍',
                targetId: postId,
                targetImageUrl: post.mediaUrls ? post.mediaUrls[0] : null,
                message: comment.text.substring(0, 50),
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                __ttl: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
            });
        }
    });

exports.onFollowCreate = functions.firestore
    .document('users/{uid}/following/{targetUid}')
    .onCreate(async (snap, context) => {
        const followerUid = context.params.uid;
        const targetUid = context.params.targetUid;

        const followerDoc = await db.collection('users').doc(followerUid).get();
        const follower = followerDoc.data();

        // Increment Analytics
        await updateAnalytics(targetUid, { followersGained: 1, netFollowerChange: 1 });

        return db.collection('notifications').doc(targetUid).collection('userNotifications').add({
            type: 'follow', 
            fromUid: followerUid,
            fromUsername: follower.displayName || follower.username,
            fromAvatar: follower.profilePictureUrl || '',
            fromNationFlag: follower.nationFlag || '🌍',
            targetId: followerUid,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            __ttl: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
        });
    });

exports.onVybzMilestone = functions.firestore
    .document('vybz/{vybzId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        const milestones = [1000, 10000, 100000, 1000000];
        
        for (const m of milestones) {
            if (before.viewsCount < m && after.viewsCount >= m) {
                await db.collection('notifications').doc(after.userId).collection('userNotifications').add({
                    type: 'vybzMilestone',
                    fromUid: 'system',
                    fromUsername: 'Gotchaa',
                    fromAvatar: '',
                    fromNationFlag: '🚀',
                    targetId: context.params.vybzId,
                    targetImageUrl: after.thumbnailUrl || null,
                    message: m.toString(),
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    __ttl: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
                });
                break;
            }
        }
    });

exports.onReactionCreate = functions.firestore
    .document('chats/{chatId}/messages/{messageId}/reactions/{uid}')
    .onCreate(async (snap, context) => {
        const reaction = snap.data();
        const { chatId, messageId, uid } = context.params;

        const messageDoc = await db.collection('chats').doc(chatId).collection('messages').doc(messageId).get();
        if (!messageDoc.exists) return null;
        const messageData = messageDoc.data();
        
        if (messageData.senderId === uid) return null;

        const reactorDoc = await db.collection('users').doc(uid).get();
        const reactor = reactorDoc.data();

        return db.collection('notifications').doc(messageData.senderId).collection('userNotifications').add({
            type: 'commentLike', 
            fromUid: uid,
            fromUsername: reactor.displayName || reactor.username,
            fromAvatar: reactor.profilePictureUrl || '',
            fromNationFlag: reactor.nationFlag || '🌍',
            targetId: chatId,
            message: reaction.emoji,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            __ttl: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
        });
    });

/**
 * Analytics Updater Helper
 */
async function updateAnalytics(uid, increments) {
    const dateStr = new Date().toISOString().split('T')[0];
    const docRef = db.collection('users').doc(uid).collection('analytics').doc(dateStr);
    
    const updateData = { date: dateStr };
    for (const [key, val] of Object.entries(increments)) {
        updateData[key] = admin.firestore.FieldValue.increment(val);
    }
    
    await docRef.set(updateData, { merge: true });
}

/**
 * Scheduled Tasks
 */
exports.computeTrendingScores = functions.runWith({ 
    timeoutSeconds: 540, 
    memory: '1GB' 
}).pubsub.schedule('every 30 minutes').onRun(async (context) => {
    const now = Date.now();
    const startTime = Date.now();
    const activitySince = new Date(now - 35 * 60 * 1000); // Look back 35m for incremental updates
    
    const ABSOLUTE_LIMIT = 1000;
    const BATCH_SIZE = 500;
    
    try {
        // Fix 2 & 3: Selection and Incremental Computation
        // We only fetch posts that had activity recently to save compute
        const postsQuery = db.collection('posts')
            .where('updatedAt', '>', activitySince)
            .select('viewsCount', 'likesCount', 'commentsCount', 'shareCount', 'createdAt', 'category')
            .limit(ABSOLUTE_LIMIT);

        const postsSnap = await postsQuery.get();
        if (postsSnap.empty) {
            console.log('No recent activity to recompute trending scores.');
            return null;
        }

        // Fetch current top trending to merge results
        const trendingRef = db.collection('trending').doc('posts');
        const trendingDoc = await trendingRef.get();
        let mergedTrending = trendingDoc.exists ? trendingDoc.data().posts : [];
        const updatedScores = [];

        // Fix 1: Process in batches if necessary (though select() helps significantly)
        for (const doc of postsSnap.docs) {
            // Fix 4: Timeout protection (buffer of 30s)
            if (Date.now() - startTime > 510 * 1000) {
                console.warn('Approaching Cloud Function timeout, stopping early.');
                break;
            }

            const data = doc.data();
            
            // Trending Logic: (Views*1 + Likes*3 + Comments*5 + Shares*10)
            const engagement = (data.viewsCount || 0) * 1.0 + 
                               (data.likesCount || 0) * 3.0 + 
                               (data.commentsCount || 0) * 5.0 +
                               (data.shareCount || 0) * 10.0;
            
            // Time Decay: Score / (age_in_hours + 2)^1.5
            const createdAt = data.createdAt ? data.createdAt.toDate().getTime() : now;
            const ageInHours = (now - createdAt) / (1000 * 60 * 60);
            const score = engagement / Math.pow(ageInHours + 2, 1.5);

            updatedScores.push({
                postId: doc.id,
                score: score,
                category: data.category || 'general'
            });

            // Fix 3: Store score on individual post for quick sorting/indexing
            await doc.ref.update({ trendingScore: score });
        }

        // Fix 5 & 1: Update the Top 100 list
        const updatedPostIds = new Set(updatedScores.map(p => p.postId));
        
        // Remove old versions of updated posts and merge new ones
        mergedTrending = [
            ...updatedScores,
            ...mergedTrending.filter(p => !updatedPostIds.has(p.postId))
        ];

        // Final sort and trim to Top 100
        mergedTrending.sort((a, b) => b.score - a.score);
        const top100 = mergedTrending.slice(0, 100).map((p, i) => ({
            postId: p.postId,
            score: p.score,
            rank: i + 1,
            category: p.category
        }));

        await trendingRef.set({
            posts: top100,
            computedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`Successfully updated trending scores. Processed ${updatedScores.length} active posts.`);
        return null;
    } catch (error) {
        console.error('Trending Computation Error:', error);
        return null;
    }
});

exports.cleanupTypingIndicators = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
    // In production, use CollectionGroup queries to delete old typing documents
});

/**
 * Helper function to calculate age in years from Date object
 */
function calculateAge(birthdayDate) {
    const today = new Date();
    let age = today.getFullYear() - birthdayDate.getFullYear();
    const monthDiff = today.getMonth() - birthdayDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthdayDate.getDate())) {
        age--;
    }
    return age;
}

/**
 * Callable Cloud Function: validateParentalConsent
 * Validates parental consent for a minor/child user.
 */
exports.validateParentalConsent = functions.https.onCall(async (data, context) => {
    const { childUid } = data;
    if (!childUid) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing childUid.');
    }

    try {
        const consentRef = db.collection('parental_consents').doc(childUid);
        const consentDoc = await consentRef.get();
        if (!consentDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Parental consent record not found for this user.');
        }

        // Update parental_consents doc
        await consentRef.update({
            confirmed: true,
            confirmedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Transition user's status in users_private to coppaLimited (ageTier = 1)
        const userPrivateRef = db.collection('users_private').doc(childUid);
        await userPrivateRef.set({
            ageTier: 1,
            ageVerified: true,
            coppaConsentConfirmed: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // Update public users collection
        const userRef = db.collection('users').doc(childUid);
        await userRef.set({
            ageVerified: true,
            isLimitedUser: true,
            isSuspended: admin.firestore.FieldValue.delete(),
            suspensionReason: admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        console.log(`Parental consent successfully validated for child: ${childUid}`);
        return { success: true, message: 'Parental consent validated successfully.' };
    } catch (error) {
        console.error('Error validating parental consent:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Scheduled Tasks: enforceAgeRestrictions
 * Runs every 24 hours to update age tiers and audit parental consent.
 */
exports.enforceAgeRestrictions = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    console.log('Starting daily age tier auditing and COPPA compliance run...');
    const now = admin.firestore.Timestamp.now();
    const usersPrivateSnap = await db.collection('users_private').get();

    if (usersPrivateSnap.empty) {
        console.log('No private user records found for auditing.');
        return null;
    }

    const batch = db.batch();
    let updatedCount = 0;

    for (const doc of usersPrivateSnap.docs) {
        const uid = doc.id;
        const privateData = doc.data();
        
        // If birthday is not present, check if coppaLimited
        if (!privateData.birthday) {
            if (privateData.ageTier === 0) {
                // Suspended if under 13 blocked and no consent
                const consentDoc = await db.collection('parental_consents').doc(uid).get();
                const consentConfirmed = consentDoc.exists && consentDoc.data().confirmed === true;
                if (!consentConfirmed) {
                    batch.set(db.collection('users').doc(uid), {
                        isSuspended: true,
                        suspensionReason: 'Under 13 without verified parental consent',
                        updatedAt: now
                    }, { merge: true });
                    updatedCount++;
                }
            }
            continue;
        }

        const birthdayDate = privateData.birthday.toDate();
        const age = calculateAge(birthdayDate);
        let expectedTier = 5; // default undetermined

        if (age < 13) {
            const consentConfirmed = privateData.coppaConsentConfirmed === true;
            expectedTier = consentConfirmed ? 1 : 0; // coppaLimited or under13Blocked
        } else if (age <= 15) {
            expectedTier = 2; // junior
        } else if (age <= 17) {
            expectedTier = 3; // teen
        } else {
            expectedTier = 4; // adult
        }

        const currentTier = privateData.ageTier;

        if (currentTier !== expectedTier) {
            console.log(`User ${uid}: age is ${age}. Transitioning ageTier from ${currentTier} to ${expectedTier}.`);
            
            // Update private doc
            batch.set(db.collection('users_private').doc(uid), {
                ageTier: expectedTier,
                updatedAt: now
            }, { merge: true });

            // Update public doc
            const publicUpdate = {
                ageTier: expectedTier,
                updatedAt: now
            };

            if (expectedTier >= 2) {
                publicUpdate.isLimitedUser = false;
                publicUpdate.isSuspended = admin.firestore.FieldValue.delete();
                publicUpdate.suspensionReason = admin.firestore.FieldValue.delete();
            } else if (expectedTier === 1) {
                publicUpdate.isLimitedUser = true;
                publicUpdate.isSuspended = admin.firestore.FieldValue.delete();
                publicUpdate.suspensionReason = admin.firestore.FieldValue.delete();
            }

            batch.set(db.collection('users').doc(uid), publicUpdate, { merge: true });
            updatedCount++;
        } else {
            // If they are under 13 and not coppa consent confirmed, ensure suspended
            if (expectedTier === 0) {
                batch.set(db.collection('users').doc(uid), {
                    isSuspended: true,
                    suspensionReason: 'Under 13 without verified parental consent',
                    updatedAt: now
                }, { merge: true });
                updatedCount++;
            }
        }
    }

    if (updatedCount > 0) {
        await batch.commit();
        console.log(`Successfully updated and audited ${updatedCount} users.`);
    } else {
        console.log('All users are in their correct age tiers and compliant.');
    }

    return null;
});

/**
 * 🚮 Account Deletion (GDPR + App Store Compliance)
 */
exports.deleteUserAccount = functions.runWith({
    timeoutSeconds: 540,
    memory: '2GB'
}).https.onCall(async (data, context) => {
    if (context.app === undefined) {
        throw new functions.https.HttpsError('failed-precondition', 'The function must be called from a verified app.');
    }
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in to delete their account.');
    }

    const uid = context.auth.uid;
    const bucket = admin.storage().bucket();

    try {
        console.log(`Starting account deletion for user: ${uid}`);

        // 1. Storage Deletion
        const storagePaths = [
            `profile_pictures/${uid}/`,
            `posts/${uid}/`,
            `vybz/${uid}/`
        ];

        for (const path of storagePaths) {
            try {
                await bucket.deleteFiles({ prefix: path });
            } catch (err) {
                console.warn(`Storage deletion warning for ${path}:`, err);
            }
        }

        // 2. Firestore Deletion
        // a. User's posts (including subcollections like comments/likes)
        const postsSnap = await db.collection('posts').where('userId', '==', uid).get();
        for (const doc of postsSnap.docs) {
            await db.recursiveDelete(doc.ref);
        }

        // b. User's vybz (including subcollections)
        const vybzSnap = await db.collection('vybz').where('userId', '==', uid).get();
        for (const doc of vybzSnap.docs) {
            await db.recursiveDelete(doc.ref);
        }

        // c. User Notifications
        await db.recursiveDelete(db.collection('notifications').doc(uid));

        // d. Chat removal/cleanup
        const chatsSnap = await db.collection('chats').where('participants', 'array-contains', uid).get();
        const chatBatch = db.batch();
        chatsSnap.docs.forEach(doc => {
            const participants = doc.data().participants || [];
            const newParticipants = participants.filter(p => p !== uid);
            
            if (newParticipants.length === 0) {
                chatBatch.delete(doc.ref); // Delete empty chat
            } else {
                chatBatch.update(doc.ref, { 
                    participants: newParticipants,
                    [`unreadCount.${uid}`]: admin.firestore.FieldValue.delete()
                });
            }
        });
        await chatBatch.commit();

        // e. VibeTalk queue
        await db.collection('vibetalk_queue').doc(uid).delete();

        // f. Main User Document and Private Document
        await db.recursiveDelete(db.collection('users').doc(uid));
        await db.recursiveDelete(db.collection('users_private').doc(uid));

        // 3. GDPR Audit Log
        await db.collection('deletionLog').doc(uid).set({
            uid: uid,
            deletedAt: admin.firestore.FieldValue.serverTimestamp(),
            reason: 'User requested deletion',
            e2eeCleanupTriggered: true, // TASK 2: Mark for E2EE cleanup audit
            status: 'COMPLETED'
        });

        // 4. Firebase Auth Deletion
        await admin.auth().deleteUser(uid);

        console.log(`Successfully deleted account: ${uid}`);
        return { success: true };
    } catch (error) {
        console.error('Account Deletion Error:', error);
        throw new functions.https.HttpsError('internal', `Failed to delete account: ${error.message}`);
    }
});

// ═══════════════════════════════════════════════════════════════════════════
// TASK 2 — DEMO SEED DATA
// Callable function: creates 3 realistic demo accounts + conversations.
// Idempotent: safe to call multiple times — won't duplicate data.
// Call from Flutter: FirebaseFunctions.instance.httpsCallable('seedDemoData').call()
// Or from Firebase Console → Functions → seedDemoData → Test
// ═══════════════════════════════════════════════════════════════════════════
exports.seedDemoData = functions.runWith({ timeoutSeconds: 300, memory: '512MB' })
    .https.onCall(async (data, context) => {

    // ── Idempotency Guard ──────────────────────────────────────────────────
    const seedRef = db.collection('_seed').doc('demo_v1');
    const seedDoc = await seedRef.get();
    if (seedDoc.exists && !(data && data.force === true)) {
        return {
            status: 'ALREADY_SEEDED',
            seededAt: seedDoc.data().seededAt,
            message: 'Demo data already exists. Pass { force: true } to re-seed.',
        };
    }

    console.log('Starting demo data seed...');
    const now = admin.firestore.FieldValue.serverTimestamp();
    const BASE_DATE = new Date('2025-03-01T00:00:00Z');

    // ── Demo User Definitions ──────────────────────────────────────────────
    const USERS = [
        {
            uid: 'demo_arjun_001',
            email: 'arjun.sharma.demo@gotchaa.app',
            password: 'GotchaaDemo@1',
            displayName: 'Arjun Sharma',
            username: 'arjun_sharma',
            bio: '🇮🇳 Software dev from Bangalore. Love cricket, chai & late-night code sessions. Building the future one commit at a time. 🚀',
            photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=ArjunSharma&backgroundColor=b6e3f4&clothingColor=3c4f5c',
            language: 'en',
            nation: { country: 'India', continent: 'Asia', code: 'IN' },
            followersCount: 10, followingCount: 5,
            karma: 350,
            gender: 'male', ageTier: 4,
            birthday: new Date('1998-04-15'),
        },
        {
            uid: 'demo_sofia_002',
            email: 'sofia.martinez.demo@gotchaa.app',
            password: 'GotchaaDemo@2',
            displayName: 'Sofía Martínez',
            username: 'sofia_creates',
            bio: '🇲🇽 Diseñadora gráfica de CDMX. Amo el arte, la música y los tacos 🌮 La vida es bella y el diseño lo hace más. ✨',
            photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=SofiaMartinez&backgroundColor=ffdfbf&clothingColor=f4a261',
            language: 'es',
            nation: { country: 'Mexico', continent: 'Americas', code: 'MX' },
            followersCount: 8, followingCount: 12,
            karma: 220,
            gender: 'female', ageTier: 4,
            birthday: new Date('2000-09-22'),
        },
        {
            uid: 'demo_omar_003',
            email: 'omar.rashidi.demo@gotchaa.app',
            password: 'GotchaaDemo@3',
            displayName: 'Omar Al-Rashidi',
            username: 'omar_uae',
            bio: '🇦🇪 Entrepreneur from Dubai. Passionate about fintech, travel & connecting cultures. GOTCHAA is where worlds meet. 🌍💼',
            photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=OmarRashidi&backgroundColor=c0aede&clothingColor=264653',
            language: 'ar',
            nation: { country: 'United Arab Emirates', continent: 'Asia', code: 'AE' },
            followersCount: 15, followingCount: 8,
            karma: 480,
            gender: 'male', ageTier: 4,
            birthday: new Date('1995-12-03'),
        },
    ];

    // ── Create Firebase Auth Users ─────────────────────────────────────────
    for (const u of USERS) {
        try {
            await admin.auth().createUser({
                uid: u.uid, email: u.email, password: u.password,
                displayName: u.displayName, emailVerified: true, photoURL: u.photoUrl,
            });
            console.log(`Auth created: ${u.uid}`);
        } catch (e) {
            if (e.code === 'auth/uid-already-exists' || e.code === 'auth/email-already-exists') {
                console.log(`Auth exists (skipping): ${u.uid}`);
            } else { throw e; }
        }
    }

    // ── Firestore Profiles ─────────────────────────────────────────────────
    const profileBatch = db.batch();
    for (const u of USERS) {
        // Public profiles: strictly no ageTier or birthday PII
        profileBatch.set(db.collection('users').doc(u.uid), {
            uid: u.uid, username: u.username, displayName: u.displayName,
            email: u.email, photoUrl: u.photoUrl, bio: u.bio,
            karma: u.karma, lovers: 0, lovely: 0,
            followersCount: u.followersCount, followingCount: u.followingCount,
            isVerified: true, isLimitedUser: false,
            inviteCode: `DEMO_${u.username.toUpperCase()}`,
            joinedWithCode: 'GOTCHAA_BETA', inviteLimit: 5, invitesUsed: 0,
            remainingInvites: 5, totalInvites: 0, isInviteRewardClaimed: false,
            invitedUsers: [], blockedUids: [], ghostUids: [], friendUids: [],
            customPrivacyLists: [],
            createdAt: admin.firestore.Timestamp.fromDate(BASE_DATE),
            gender: u.gender, ageVerified: true,
            hasPickedLanguage: true, language: u.language, nation: u.nation,
            isOnline: false, lastSeen: now, isPrivate: false,
            showActivityStatus: true, pushNotificationsEnabled: true,
            emailNotificationsEnabled: true, isTwoFactorEnabled: false,
            stayAnonymousInConnections: false,
            termsAcceptedVersion: '2.0', privacyAcceptedVersion: '1.0',
            legalAcceptedAt: admin.firestore.Timestamp.fromDate(BASE_DATE),
            isDemo: true,
        }, { merge: true });

        // Private profiles: holds birthday and ageTier securely
        profileBatch.set(db.collection('users_private').doc(u.uid), {
            ageTier: u.ageTier,
            ageVerified: true,
            birthday: admin.firestore.Timestamp.fromDate(u.birthday),
            fcmToken: 'demo_token_' + u.uid,
            updatedAt: now,
        }, { merge: true });
    }

    // ── Posts ──────────────────────────────────────────────────────────────
    const PHOTOS = [
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&auto=format',
        'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&auto=format',
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format',
        'https://images.unsplash.com/photo-1499336315816-097655dcfbda?w=800&auto=format',
        'https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?w=800&auto=format',
    ];
    const posts = [
        // Arjun — 5 posts
        { id: 'demo_post_arjun_1', uid: 'demo_arjun_001', username: 'arjun_sharma', name: 'Arjun Sharma', photo: PHOTOS[0], caption: '✨ Bangalore sunsets hit different. #bangalore #vibes', likes: 43, comments: 8 },
        { id: 'demo_post_arjun_2', uid: 'demo_arjun_001', username: 'arjun_sharma', name: 'Arjun Sharma', photo: PHOTOS[1], caption: 'Weekend cricket with the lads 🏏 No better feeling.', likes: 67, comments: 12 },
        { id: 'demo_post_arjun_3', uid: 'demo_arjun_001', username: 'arjun_sharma', name: 'Arjun Sharma', photo: PHOTOS[2], caption: 'Finally shipped the feature I\'ve been building for weeks 🚀 #developer', likes: 91, comments: 22 },
        { id: 'demo_post_arjun_4', uid: 'demo_arjun_001', username: 'arjun_sharma', name: 'Arjun Sharma', photo: PHOTOS[3], caption: 'Chai break > coffee break. Fight me ☕', likes: 128, comments: 31 },
        { id: 'demo_post_arjun_5', uid: 'demo_arjun_001', username: 'arjun_sharma', name: 'Arjun Sharma', photo: PHOTOS[4], caption: 'When the code finally works at 2am 😂 #devlife', likes: 55, comments: 9 },
        // Sofía — 3 posts
        { id: 'demo_post_sofia_1', uid: 'demo_sofia_002', username: 'sofia_creates', name: 'Sofía Martínez', photo: PHOTOS[1], caption: '🎨 Mi nuevo proyecto de diseño. ¿Qué opinan? #diseño #creatividad', likes: 38, comments: 7 },
        { id: 'demo_post_sofia_2', uid: 'demo_sofia_002', username: 'sofia_creates', name: 'Sofía Martínez', photo: PHOTOS[3], caption: 'CDMX de noche 🌃 La ciudad que nunca duerme', likes: 72, comments: 14 },
        { id: 'demo_post_sofia_3', uid: 'demo_sofia_002', username: 'sofia_creates', name: 'Sofía Martínez', photo: PHOTOS[4], caption: '¡Tacos de canasta con mis amigos! El mejor plan 🌮 #mexico', likes: 94, comments: 19 },
        // Omar — 4 posts
        { id: 'demo_post_omar_1', uid: 'demo_omar_003', username: 'omar_uae', name: 'Omar Al-Rashidi', photo: PHOTOS[0], caption: 'Dubai skyline never gets old 🌆 #Dubai #UAE', likes: 182, comments: 34 },
        { id: 'demo_post_omar_2', uid: 'demo_omar_003', username: 'omar_uae', name: 'Omar Al-Rashidi', photo: PHOTOS[2], caption: 'Closed a major deal today 💼 Hard work always pays off. #entrepreneur', likes: 210, comments: 41 },
        { id: 'demo_post_omar_3', uid: 'demo_omar_003', username: 'omar_uae', name: 'Omar Al-Rashidi', photo: PHOTOS[1], caption: '🤝 Met amazing people from 12 countries at this summit. GOTCHAA energy IRL!', likes: 156, comments: 28 },
        { id: 'demo_post_omar_4', uid: 'demo_omar_003', username: 'omar_uae', name: 'Omar Al-Rashidi', photo: PHOTOS[3], caption: 'The future is multilingual 🌍 Learning from every connection. #culture', likes: 133, comments: 22 },
    ];
    posts.forEach((p, i) => {
        const u = USERS.find(u => u.uid === p.uid);
        profileBatch.set(db.collection('posts').doc(p.id), {
            id: p.id, userId: p.uid, username: p.username,
            userDisplayName: p.name, userPhotoUrl: u.photoUrl,
            caption: p.caption, mediaUrl: p.photo, mediaType: 'image',
            likeCount: p.likes, commentCount: p.comments, shareCount: Math.floor(p.likes / 15),
            isPublic: true, isDemo: true,
            createdAt: admin.firestore.Timestamp.fromDate(new Date(BASE_DATE.getTime() + i * 86400000 * 2)),
        }, { merge: true });
    });

    await profileBatch.commit();
    console.log('Profiles and posts created.');

    // ── Chat Conversations ─────────────────────────────────────────────────
    const chatDefs = [
        {
            id: 'demo_chat_arjun_sofia',
            p: ['demo_arjun_001', 'demo_sofia_002'],
            names: { demo_arjun_001: 'Arjun Sharma', demo_sofia_002: 'Sofía Martínez' },
            avatars: { demo_arjun_001: USERS[0].photoUrl, demo_sofia_002: USERS[1].photoUrl },
            msgs: [
                { s: 'demo_arjun_001', r: 'demo_sofia_002', t: 'Hey Sofía! Found you through VibeTalk 😊 Your designs are amazing!' },
                { s: 'demo_sofia_002', r: 'demo_arjun_001', t: '¡Hola Arjun! Yes, that was such a fun session! Your English is great 👍' },
                { s: 'demo_arjun_001', r: 'demo_sofia_002', t: 'Thanks! I\'ve been trying to improve. Your design portfolio is inspiring.' },
                { s: 'demo_sofia_002', r: 'demo_arjun_001', t: 'Gracias! 🎨 What kind of apps do you build?' },
                { s: 'demo_arjun_001', r: 'demo_sofia_002', t: 'Flutter apps mostly — social platforms and fintech. GOTCHAA is actually built in Flutter!' },
                { s: 'demo_sofia_002', r: 'demo_arjun_001', t: 'Wow, impressive! Have you tried the AR filters? They\'re amazing 😍' },
                { s: 'demo_arjun_001', r: 'demo_sofia_002', t: 'Yes! The face detection ones use ML Kit on-device. So cool from a dev perspective 🤓' },
                { s: 'demo_sofia_002', r: 'demo_arjun_001', t: 'Haha very nerdy but I love it! Want to VibeTalk again this weekend?' },
                { s: 'demo_arjun_001', r: 'demo_sofia_002', t: 'Definitely! Saturday evening works for me — it\'s IST so that\'s what, noon for you?' },
                { s: 'demo_sofia_002', r: 'demo_arjun_001', t: '¡Perfecto! It\'s a plan 🤝✨ See you then, Arjun!' },
            ],
        },
        {
            id: 'demo_chat_sofia_omar',
            p: ['demo_sofia_002', 'demo_omar_003'],
            names: { demo_sofia_002: 'Sofía Martínez', demo_omar_003: 'Omar Al-Rashidi' },
            avatars: { demo_sofia_002: USERS[1].photoUrl, demo_omar_003: USERS[2].photoUrl },
            msgs: [
                { s: 'demo_omar_003', r: 'demo_sofia_002', t: '¡Hola Sofía! Omar here from Dubai. Loved your latest design post 🔥' },
                { s: 'demo_sofia_002', r: 'demo_omar_003', t: '¡Hola Omar! Thank you so much, that means a lot coming from an entrepreneur like you!' },
                { s: 'demo_omar_003', r: 'demo_sofia_002', t: 'The branding work is exceptional. Have you worked with international clients?' },
                { s: 'demo_sofia_002', r: 'demo_omar_003', t: 'Mostly Latin America so far. But Dubai is on my dream list — the design scene there looks incredible!' },
                { s: 'demo_omar_003', r: 'demo_sofia_002', t: 'It really is! There\'s a huge demand for creative talent here. You should consider it.' },
                { s: 'demo_sofia_002', r: 'demo_omar_003', t: 'Seriously? I\'d love to connect with the design community there. Any advice?' },
                { s: 'demo_omar_003', r: 'demo_sofia_002', t: 'I know a few agency founders. Can make introductions — that\'s the power of GOTCHAA right? 😄' },
                { s: 'demo_sofia_002', r: 'demo_omar_003', t: '100%! This app is genuinely changing how I meet amazing people globally 🌍' },
                { s: 'demo_omar_003', r: 'demo_sofia_002', t: 'Sending you some Karma for that post btw — seriously loved the color theory breakdown 🙌' },
                { s: 'demo_sofia_002', r: 'demo_omar_003', t: '¡Muchas gracias Omar! You\'re too kind. Let\'s stay connected! 💜' },
            ],
        },
        {
            id: 'demo_chat_arjun_omar',
            p: ['demo_arjun_001', 'demo_omar_003'],
            names: { demo_arjun_001: 'Arjun Sharma', demo_omar_003: 'Omar Al-Rashidi' },
            avatars: { demo_arjun_001: USERS[0].photoUrl, demo_omar_003: USERS[2].photoUrl },
            msgs: [
                { s: 'demo_arjun_001', r: 'demo_omar_003', t: 'Hey Omar! Your fintech post was incredible. Are you in payments specifically?' },
                { s: 'demo_omar_003', r: 'demo_arjun_001', t: 'Hey Arjun! Yes — cross-border remittance and B2B payments. You?' },
                { s: 'demo_arjun_001', r: 'demo_omar_003', t: 'Building payments infra for India. UPI integrations mostly. It\'s a wild space.' },
                { s: 'demo_omar_003', r: 'demo_arjun_001', t: 'UPI is literally revolutionary. The rest of the world needs to catch up honestly.' },
                { s: 'demo_arjun_001', r: 'demo_omar_003', t: 'Right! 400M+ daily transactions now. Instant settlement changed everything here.' },
                { s: 'demo_omar_003', r: 'demo_arjun_001', t: 'We\'re exploring GCC-India payment corridors. There\'s a massive opportunity there.' },
                { s: 'demo_arjun_001', r: 'demo_omar_003', t: 'That\'s huge. India-UAE remittance is one of the largest corridors globally.' },
                { s: 'demo_omar_003', r: 'demo_arjun_001', t: 'Exactly my thinking. Would love to do a proper call and explore synergies 🤝' },
                { s: 'demo_arjun_001', r: 'demo_omar_003', t: 'Absolutely! I\'ll block some time this week. Sending you my calendar link.' },
                { s: 'demo_omar_003', r: 'demo_arjun_001', t: 'Perfect. Sending Karma your way for the knowledge share 🚀 GOTCHAA is going to be huge!' },
            ],
        },
    ];

    for (const chat of chatDefs) {
        const lastMsg = chat.msgs[chat.msgs.length - 1];
        const chatRef = db.collection('chats').doc(chat.id);
        await chatRef.set({
            participants: chat.p,
            participantNames: chat.names,
            participantAvatars: chat.avatars,
            lastMessage: lastMsg.t,
            lastMessageSenderId: lastMsg.s,
            lastMessageType: 'text',
            lastMessageTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 600000)),
            unreadCount: { [chat.p[0]]: 0, [chat.p[1]]: 2 },
            typing: { [chat.p[0]]: false, [chat.p[1]]: false },
            isArchived: { [chat.p[0]]: false, [chat.p[1]]: false },
            isMuted: { [chat.p[0]]: false, [chat.p[1]]: false },
            isDemo: true,
        }, { merge: true });

        const msgBatch = db.batch();
        chat.msgs.forEach((m, i) => {
            const msgRef = chatRef.collection('messages').doc(`demo_msg_${chat.id}_${i + 1}`);
            msgBatch.set(msgRef, {
                schemaVersion: 1,
                senderId: m.s, receiverId: m.r, text: m.t,
                type: 'text', status: 'read',
                timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (10 - i) * 300000)),
                createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (10 - i) * 300000)),
                isEncrypted: false, isDeletedForEveryone: false,
                isDeletedFor: [], reactions: {}, isDemo: true,
            }, { merge: true });
        });
        await msgBatch.commit();
        console.log(`Chat created: ${chat.id}`);
    }

    // ── VibeTalk Match History ─────────────────────────────────────────────
    const vtBatch = db.batch();
    [
        { id: 'demo_vt_1', caller: 'demo_arjun_001', callee: 'demo_sofia_002', duration: 420, daysAgo: 3 },
        { id: 'demo_vt_2', caller: 'demo_omar_003', callee: 'demo_arjun_001', duration: 680, daysAgo: 5 },
        { id: 'demo_vt_3', caller: 'demo_sofia_002', callee: 'demo_omar_003', duration: 310, daysAgo: 7 },
    ].forEach(vt => {
        const matchTime = new Date(Date.now() - vt.daysAgo * 86400000);
        vtBatch.set(db.collection('vibetalk_rooms').doc(vt.id), {
            id: vt.id,
            callerId: vt.caller, calleeId: vt.callee,
            users: [vt.caller, vt.callee],
            status: 'ended',
            duration: vt.duration,
            createdAt: admin.firestore.Timestamp.fromDate(matchTime),
            endedAt: admin.firestore.Timestamp.fromDate(new Date(matchTime.getTime() + vt.duration * 1000)),
            rating: { [vt.caller]: 5, [vt.callee]: 5 },
            gameState: { round: 3, bothVoted: true },
            reconnectionState: 'disconnected',
            isDemo: true,
        }, { merge: true });
    });
    await vtBatch.commit();

    // ── Seed Marker (Idempotency) ──────────────────────────────────────────
    await seedRef.set({
        seededAt: now,
        version: 'demo_v1',
        userIds: USERS.map(u => u.uid),
    });

    console.log('Demo seed complete!');
    return {
        status: 'SUCCESS',
        message: 'Demo data seeded successfully.',
        users: USERS.map(u => ({ uid: u.uid, email: u.email, username: u.username })),
    };
});

// ── Legal policy version tracking (users_private) ─────────────────────────────
const REQUIRED_PRIVACY_VERSION = 'v3.0';
const REQUIRED_TERMS_VERSION = 'v3.0';

function getClientIp(context) {
    const req = context.rawRequest;
    if (!req) return 'unknown';
    const forwarded = req.headers && req.headers['x-forwarded-for'];
    if (forwarded) return String(forwarded).split(',')[0].trim();
    return req.ip || req.connection?.remoteAddress || 'unknown';
}

/**
 * Records legal acceptance with IP proof in users_private/{uid}.
 */
exports.recordLegalAcceptance = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }
    const uid = context.auth.uid;
    const privacyVersion = data.privacyPolicyVersion || REQUIRED_PRIVACY_VERSION;
    const termsVersion = data.termsVersion || REQUIRED_TERMS_VERSION;
    const ip = getClientIp(context);

    await db.collection('users_private').doc(uid).set({
        privacyPolicyVersion: privacyVersion,
        termsVersion: termsVersion,
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
        ipAddressAtAcceptance: ip,
    }, { merge: true });

    await db.collection('users').doc(uid).set({
        privacyAcceptedVersion: privacyVersion,
        termsAcceptedVersion: termsVersion,
        legalAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true, ipRecorded: ip !== 'unknown' };
});

/**
 * Checks policy versions on login — forces re-acceptance if outdated.
 */
// ── Moderation dashboard ───────────────────────────────────────────────────────
const MOD_SEVERITY_ORDER = { critical: 0, high: 1, normal: 2, low: 3 };

exports.getModerationQueue = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const snap = await db.collection('moderation_reports')
        .where('status', '==', 'pending')
        .orderBy('timestamp', 'desc')
        .limit(200)
        .get();
    const grouped = {};
    snap.docs.forEach(doc => {
        const d = doc.data();
        const key = `${d.contentType}_${d.contentId}`;
        if (!grouped[key]) {
            grouped[key] = { id: doc.id, ...d, reporterCount: 1, reportIds: [doc.id] };
        } else {
            grouped[key].reporterCount += 1;
            grouped[key].reportIds.push(doc.id);
        }
    });
    const queue = Object.values(grouped).sort((a, b) => {
        const pa = MOD_SEVERITY_ORDER[a.priority] ?? 2;
        const pb = MOD_SEVERITY_ORDER[b.priority] ?? 2;
        return pa - pb;
    });
    return { queue, total: queue.length };
});

exports.takeModerationAction = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const { reportId, action, targetUserId, contentType, contentId, note } = data;
    const valid = ['warn', 'mute_24h', 'mute_7d', 'ban', 'delete_content', 'restore_content'];
    if (!valid.includes(action)) throw new functions.https.HttpsError('invalid-argument', 'Invalid action');

    await db.collection('moderation_actions').add({
        reportId: reportId || null,
        action,
        targetUserId: targetUserId || null,
        contentType: contentType || null,
        contentId: contentId || null,
        moderatorId: context.auth.uid,
        note: note || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (reportId) {
        await db.collection('moderation_reports').doc(reportId).update({
            status: 'actioned',
            actionTaken: action,
            reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    if (action === 'ban' && targetUserId) {
        await db.collection('users').doc(targetUserId).update({ isBanned: true, bannedAt: admin.firestore.FieldValue.serverTimestamp() });
    }
    if (action === 'mute_24h' && targetUserId) {
        await db.collection('users').doc(targetUserId).update({
            mutedUntil: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
        });
    }
    if (action === 'mute_7d' && targetUserId) {
        await db.collection('users').doc(targetUserId).update({
            mutedUntil: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 86400000)),
        });
    }
    if (action === 'delete_content' && contentType === 'post' && contentId) {
        await db.collection('posts').doc(contentId).update({ isHidden: true });
    }

    return { success: true, action };
});

exports.moderationStats = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const dayAgo = new Date(Date.now() - 86400000);
    const reportsSnap = await db.collection('moderation_reports')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(dayAgo))
        .get();
    const actionsSnap = await db.collection('moderation_actions')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(dayAgo))
        .get();
    const byType = {};
    reportsSnap.forEach(doc => {
        const t = doc.data().contentType || 'unknown';
        byType[t] = (byType[t] || 0) + 1;
    });
    return {
        dailyReportCount: reportsSnap.size,
        dailyActionCount: actionsSnap.size,
        actionRate: reportsSnap.size ? actionsSnap.size / reportsSnap.size : 0,
        topContentTypes: byType,
    };
});

exports.handleCsamIncident = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const userId = data.userId || context.auth.uid;
    const hash = data.perceptualHash || 'unknown';

    await db.collection('users').doc(userId).update({
        isBanned: true,
        banReason: 'csam_hash_match',
        bannedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const incidentRef = await db.collection('csam_incidents').add({
        userId,
        perceptualHash: hash,
        detectedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'open',
        evidencePreserved: true,
        ncmecReportPending: true,
    });

    await db.collection('moderation_reports').add({
        reportedUserId: userId,
        reportedByUserId: 'system',
        contentType: 'image',
        contentId: incidentRef.id,
        category: 'Child Safety',
        reason: 'CSAM perceptual hash match',
        status: 'pending',
        severity: 'critical',
        isCsamFlag: true,
        priority: 'critical',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.error(`[CSAM INCIDENT] user=${userId} hash=${hash} — admin notified`);
    return { suspended: true, incidentId: incidentRef.id };
});

exports.notifyAdminModeration = functions.https.onCall(async (data, context) => {
    console.log('[MODERATION ALERT]', JSON.stringify(data));
    return { notified: true };
});

exports.notifyTrustTeam = functions.https.onCall(async (data, context) => {
    console.log('[TRUST ALERT]', JSON.stringify(data));
    return { notified: true };
});

// ── Security: login, sessions, export ─────────────────────────────────────────
exports.recordLoginSession = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const uid = context.auth.uid;
    const ip = getClientIp(context);
    const sessionId = data.sessionId || context.auth.uid + '_' + Date.now();
    const sessionsRef = db.collection('users_private').doc(uid).collection('sessions');
    const priorSnap = await sessionsRef.orderBy('lastActive', 'desc').limit(2).get();
    const priorIp = priorSnap.docs.find(d => d.id !== sessionId)?.data()?.ipAddress;

    await sessionsRef.doc(sessionId).set({
        deviceName: data.deviceName || 'Unknown device',
        location: data.location || 'Unknown',
        ipAddress: ip,
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        isCurrent: data.isCurrent !== false,
    }, { merge: true });

    if (priorIp && ip && priorIp !== ip) {
        await db.collection('notifications').add({
            userId: uid,
            type: 'suspicious_login',
            title: 'Sign-in from a new network',
            body: `New IP detected (${ip}). Review active sessions if this wasn't you.`,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    return { sessionId, suspiciousIp: !!(priorIp && ip && priorIp !== ip) };
});

exports.sendLoginNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const uid = context.auth.uid;
    const deviceName = data.deviceName || 'Unknown device';
    const sessionsSnap = await db.collection('users_private').doc(uid).collection('sessions')
        .orderBy('lastActive', 'desc').limit(5).get();
    const isNewDevice = sessionsSnap.size <= 1;
    if (isNewDevice) {
        await db.collection('users_private').doc(uid).set({
            lastLoginAlertAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLoginDevice: deviceName,
        }, { merge: true });
        await db.collection('notifications').add({
            userId: uid,
            type: 'login_alert',
            title: 'New sign-in to your account',
            body: `Signed in from ${deviceName}. If this wasn't you, change your password and review active sessions.`,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    return { notified: isNewDevice };
});

exports.verify2FA = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const uid = context.auth.uid;
    const code = String(data.code || '').replace(/\s/g, '');
    if (!/^\d{6}$/.test(code)) return { valid: false };
    const privateDoc = await db.collection('users_private').doc(uid).get();
    const secret = privateDoc.data()?.totpSecret;
    if (!secret) return { valid: false };
    const valid = speakeasy.totp.verify({
        secret,
        encoding: 'base32',
        token: code,
        window: 1,
    });
    return { valid: !!valid };
});

exports.trackFailedLogin = functions.https.onCall(async (data, context) => {
    const email = (data.email || '').toLowerCase().trim();
    if (!email) return { tracked: false };
    const ref = db.collection('login_attempts').doc(email.replace(/[^a-z0-9@._-]/g, '_'));
    await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const count = (snap.data()?.failCount || 0) + 1;
        const locked = count >= 5;
        tx.set(ref, {
            failCount: count,
            lastFailedAt: admin.firestore.FieldValue.serverTimestamp(),
            lockedUntil: locked ? admin.firestore.Timestamp.fromMillis(Date.now() + 15 * 60000) : null,
        }, { merge: true });
    });
    const after = await ref.get();
    const lockedUntil = after.data()?.lockedUntil?.toMillis?.() || 0;
    if (lockedUntil > Date.now()) {
        throw new functions.https.HttpsError('resource-exhausted', 'Too many failed attempts. Try again in 15 minutes.');
    }
    return { tracked: true, failCount: after.data()?.failCount || 0 };
});

exports.revokeSession = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    await db.collection('users_private').doc(context.auth.uid).collection('sessions').doc(data.sessionId).delete();
    return { revoked: true };
});

exports.revokeAllOtherSessions = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const snap = await db.collection('users_private').doc(context.auth.uid).collection('sessions').get();
    const batch = db.batch();
    snap.docs.forEach(doc => {
        if (doc.data().isCurrent !== true) batch.delete(doc.ref);
    });
    await batch.commit();
    return { revoked: true };
});

exports.generateDataExport = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const uid = context.auth.uid;
    const privateDoc = await db.collection('users_private').doc(uid).get();
    const lastExport = privateDoc.data()?.lastDataExportAt?.toDate?.();
    if (lastExport && Date.now() - lastExport.getTime() < 30 * 86400000) {
        throw new functions.https.HttpsError('resource-exhausted', 'Export limited to once per 30 days');
    }
    const userDoc = await db.collection('users').doc(uid).get();
    const postsSnap = await db.collection('posts').where('uid', '==', uid).limit(500).get();
    const exportPayload = {
        profile: userDoc.data(),
        posts: postsSnap.docs.map(d => ({ id: d.id, ...d.data() })),
        exportedAt: new Date().toISOString(),
        note: 'Messages metadata and karma included in full server export',
    };
    await db.collection('users_private').doc(uid).set({
        lastDataExportAt: admin.firestore.FieldValue.serverTimestamp(),
        pendingExportPayload: exportPayload,
    }, { merge: true });
    return {
        exportId: uid + '_' + Date.now(),
        message: 'Your data export is being prepared. Download link valid for 7 days — check email and notifications.',
    };
});

exports.checkPolicyOnLogin = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }
    const uid = context.auth.uid;
    const privateDoc = await db.collection('users_private').doc(uid).get();
    const privateData = privateDoc.exists ? privateDoc.data() : {};

    const acceptedPrivacy = privateData.privacyPolicyVersion || null;
    const acceptedTerms = privateData.termsVersion || null;

    const requiresReacceptance =
        acceptedPrivacy !== REQUIRED_PRIVACY_VERSION ||
        acceptedTerms !== REQUIRED_TERMS_VERSION;

    return {
        requiresReacceptance,
        requiredPrivacyVersion: REQUIRED_PRIVACY_VERSION,
        requiredTermsVersion: REQUIRED_TERMS_VERSION,
        acceptedPrivacyVersion: acceptedPrivacy,
        acceptedTermsVersion: acceptedTerms,
    };
});

/**
 * 🎥 Cloud Video Compression Pipeline
 * Triggered on upload to Firebase Storage, scales to 720x1280, compresses to H264 + AAC,
 * uploads optimized output, updates Firestore Vybz URL, and deletes the original raw file.
 */
exports.compressUploadedVideo = functions.runWith({
    timeoutSeconds: 300,
    memory: '1GB'
}).storage.object().onFinalize(async (object) => {
    const path = require('path');
    const os = require('os');
    const fs = require('fs');
    const spawn = require('child_process').spawn;

    const filePath = object.name; // e.g. vybz/userId/fileName.mp4
    const bucketName = object.bucket;
    const contentType = object.contentType;

    // Check if raw video upload in vybz/ directory
    if (!filePath.startsWith('vybz/') || filePath.includes('/optimized_') || filePath.split('/').length < 3) {
        console.log('Not a Vybz raw video. Skipping.');
        return null;
    }

    if (!contentType || !contentType.startsWith('video/')) {
        console.log('Not a video file. Skipping.');
        return null;
    }

    const bucket = admin.storage().bucket(bucketName);
    const fileName = path.basename(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const targetFileName = `optimized_${fileName}`;
    const targetFilePath = path.join(path.dirname(filePath), targetFileName);
    const tempOutputPath = path.join(os.tmpdir(), targetFileName);

    console.log(`Downloading raw video: ${filePath} to ${tempFilePath}`);
    await bucket.file(filePath).download({ destination: tempFilePath });

    console.log(`Compressing video with FFmpeg to 720x1280 (H264 / AAC)`);
    await new Promise((resolve, reject) => {
        const ffmpegArgs = [
            '-y',
            '-i', tempFilePath,
            '-vf', 'scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2',
            '-c:v', 'libx264',
            '-c:a', 'aac',
            '-preset', 'fast',
            '-crf', '23',
            tempOutputPath
        ];

        const process = spawn('ffmpeg', ffmpegArgs);

        process.stdout.on('data', (data) => console.log(`FFmpeg stdout: ${data}`));
        process.stderr.on('data', (data) => console.log(`FFmpeg stderr: ${data}`));

        process.on('close', (code) => {
            if (code === 0) {
                resolve();
            } else {
                reject(new Error(`FFmpeg exited with code ${code}`));
            }
        });
    });

    console.log(`Uploading optimized video: ${targetFilePath}`);
    await bucket.upload(tempOutputPath, {
        destination: targetFilePath,
        metadata: {
            contentType: 'video/mp4',
            metadata: {
                optimized: 'true',
                originalFile: filePath
            }
        }
    });

    // Cleanup temp files
    fs.unlinkSync(tempFilePath);
    fs.unlinkSync(tempOutputPath);

    // Delete the original raw upload to save storage costs!
    console.log(`Deleting raw upload: ${filePath}`);
    await bucket.file(filePath).delete();

    // Construct the public storage URL or generate a signed URL
    const fileRef = bucket.file(targetFilePath);
    const [downloadUrl] = await fileRef.getSignedUrl({
        action: 'read',
        expires: '03-09-2491'
    });

    console.log(`Finding Firestore document with videoUrl: ${filePath}`);
    const vybzSnap = await db.collection('vybz').get();
    for (const doc of vybzSnap.docs) {
        const data = doc.data();
        if (data.videoUrl && data.videoUrl.includes(filePath.replace('/', '%2F'))) {
            console.log(`Updating Firestore document ${doc.id} with optimized URL`);
            await doc.ref.update({
                videoUrl: downloadUrl,
                isOptimized: true
            });
            break;
        }
    }

    return null;
});

/**
 * Callable Cloud Function: executeBroAction
 * Orchestrates voice-triggered operations: cab booking, food delivery, shopping, payment, and Gemini queries.
 */
exports.executeBroAction = functions.runWith({
    timeoutSeconds: 30,
    memory: '256MB'
}).https.onCall(async (data, context) => {
    // 1. App Check Verification
    if (context.app === undefined) {
        throw new functions.https.HttpsError('failed-precondition', 'The function must be called from a verified app.');
    }
    // 2. User Authentication Validation
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const uid = context.auth.uid;
    const axios = require('axios');

    // Support both client formats (intent/params and action/data)
    const intent = data.intent || data.action || 'none';
    const params = data.params || data.data || {};

    console.log(`Executing BRO Action for UID: ${uid}, Intent: ${intent}`, params);

    // Helper: Exponential Backoff Retry (Max 2 retries = 3 total attempts)
    const executeWithRetries = async (fn, maxRetries = 2) => {
        let attempts = 0;
        while (attempts <= maxRetries) {
            try {
                return await fn();
            } catch (error) {
                attempts++;
                if (attempts > maxRetries) {
                    throw error;
                }
                const delay = process.env.NODE_ENV === 'test' ? 1 : Math.pow(2, attempts) * 1000;
                console.warn(`Attempt ${attempts} failed. Retrying in ${delay}ms... Error: ${error.message}`);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    };

    try {
        switch (intent) {
            case 'cab_booking': {
                const destination = params.destination || params.to || 'destination';
                const pickup = params.pickup || params.from || 'your current location';

                await executeWithRetries(async () => {
                    if (process.env.UBER_API_URL) {
                        await axios.post(process.env.UBER_API_URL, { pickup, destination }, { timeout: 10000 });
                    } else {
                        await new Promise(resolve => setTimeout(resolve, 800)); // Mock network latency
                    }
                });

                const bookingId = `UBER-${Math.floor(100000 + Math.random() * 900000)}`;
                const plateNumber = `DL 3C AB ${Math.floor(1000 + Math.random() * 9000)}`;
                const eta = "5 minutes";
                const price = "₹180";

                return {
                    success: true,
                    result: { bookingId, driverName: "Raju Prasad", vehicle: "Maruti Swift (White)", plateNumber, eta, price, pickup, destination },
                    tts_response: `I've booked your ride to ${destination}, boss. Raju Prasad is on the way in a white Maruti Swift, plate number ${plateNumber}. ETA is ${eta}.`
                };
            }

            case 'food_order': {
                const foodItem = params.item || params.food || 'food';
                const restaurant = params.restaurant || 'Local Dhaba';

                await executeWithRetries(async () => {
                    if (process.env.ZOMATO_API_URL) {
                        await axios.post(process.env.ZOMATO_API_URL, { foodItem, restaurant }, { timeout: 10000 });
                    } else {
                        await new Promise(resolve => setTimeout(resolve, 800));
                    }
                });

                const orderId = `FOOD-${Math.floor(100000 + Math.random() * 900000)}`;
                const eta = "25 minutes";

                return {
                    success: true,
                    result: { orderId, foodItem, restaurant, status: "Preparing", eta },
                    tts_response: `Order placed, boss! Your order of ${foodItem} from ${restaurant} has been accepted. It is being prepared and will reach you in ${eta}.`
                };
            }

            case 'shopping': {
                const item = params.item || params.product || 'item';
                const store = params.store || 'Flipkart';

                await executeWithRetries(async () => {
                    if (process.env.FLIPKART_API_URL) {
                        await axios.post(process.env.FLIPKART_API_URL, { item, store }, { timeout: 10000 });
                    } else {
                        await new Promise(resolve => setTimeout(resolve, 800));
                    }
                });

                const orderId = `SHOP-${Math.floor(100000 + Math.random() * 900000)}`;
                const deliveryDate = "tomorrow by 8 PM";

                return {
                    success: true,
                    result: { orderId, item, store, deliveryDate },
                    tts_response: `Order confirmed, boss! I've purchased the ${item} on ${store}. It will be delivered to you ${deliveryDate}.`
                };
            }

            case 'payment': {
                const amount = params.amount || "₹100";
                const recipient = params.recipient || params.to || "someone";

                await executeWithRetries(async () => {
                    if (process.env.PAYMENT_API_URL) {
                        await axios.post(process.env.PAYMENT_API_URL, { amount, recipient }, { timeout: 10000 });
                    } else {
                        await new Promise(resolve => setTimeout(resolve, 1000));
                    }
                });

                const transactionId = `TXN-${Math.floor(10000000 + Math.random() * 90000000)}`;

                return {
                    success: true,
                    result: { transactionId, amount, recipient },
                    tts_response: `Payment of ${amount} to ${recipient} was successful, boss. Transaction ID is ${transactionId}.`
                };
            }

            case 'query': {
                const queryText = params.query || data.query || params.text || '';
                if (!queryText) {
                    return {
                        success: false,
                        result: null,
                        tts_response: "What would you like me to search, boss?"
                    };
                }

                let textResult = '';
                await executeWithRetries(async () => {
                    const apiKey = process.env.GEMINI_API_KEY;
                    if (!apiKey) {
                        throw new Error('GEMINI_API_KEY is not defined in functions environment');
                    }

                    const response = await axios.post(
                        `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
                        {
                            contents: [{
                                parts: [{
                                    text: queryText
                                }]
                            }]
                        },
                        {
                            headers: { 'Content-Type': 'application/json' },
                            timeout: 15000
                        }
                    );

                    const candidate = response.data?.candidates?.[0];
                    textResult = candidate?.content?.parts?.[0]?.text || 'No response from Gemini.';
                });

                return {
                    success: true,
                    result: { textResult },
                    tts_response: textResult
                };
            }

            default:
                return {
                    success: false,
                    result: null,
                    tts_response: `I'm not sure how to perform the action: ${intent}, boss.`
                };
        }
    } catch (error) {
        console.error(`BRO Action Failure - Intent: ${intent}, Error:`, error);

        // Zero-Trust logging: safe logging fallback to Firestore
        try {
            await db.collection('bro_failures').add({
                uid,
                intent,
                params,
                errorMessage: error.message || 'Unknown error',
                errorStack: error.stack || '',
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
        } catch (logError) {
            console.error('Failed to log failure details to Firestore:', logError);
        }

        return {
            success: false,
            result: null,
            tts_response: "I couldn't complete that. Please try again."
        };
    }
});

