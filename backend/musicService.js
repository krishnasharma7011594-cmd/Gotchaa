const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { v4: uuidv4 } = require('uuid');

// ============================================================================
// --- GEMINI LYRIA 3 API INTEGRATION STUB (MusicGenerationProvider) ---
// ============================================================================
class MusicGenerationProvider {
  /**
   * Generates a short audio clip from a text prompt.
   * Stubbed for now.
   * 
   * @param {string} prompt Text prompt describing the music to generate.
   * @param {string} model Model name to use (e.g. "lyria-3-clip-preview").
   * @returns {Promise<string>} Base64-encoded audio data (MP3/AAC).
   */
  static async generateMusicClip(prompt, model) {
    try {
      console.log(`[MusicGenerationProvider] Generating clip for prompt: "${prompt}" using model: "${model}"`);
      
      // Real Gemini Lyria 3 API Call:
      // In production, when the API is active:
      // const apiKey = process.env.GEMINI_API_KEY;
      // const response = await axios.post(
      //   `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateAudio?key=${apiKey}`,
      //   {
      //     prompt: prompt,
      //     audioConfig: {
      //       durationSeconds: 30,
      //       mimeType: "audio/mp3"
      //     }
      //   }
      // );
      // return response.data.audioContent; // Returns base64 encoded audio string
      
      // Simulate API latency
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Mock base64 MP3 content (a very small silent/simple MP3 block)
      const mockBase64Mp3 = 
        'SUQzBAAAAAAAAFRYWFgAAAASAAADbWFqb3JfYnJhbmQAbXA0MgBUWFhYAAAAEgAAA21pbm9yX3ZlcnNpb24AMABUWFhYAAAAHAAAA2NvbXBhdGlibGVfYnJhbmRzAG1wNDJtcDQxAFRQRTEAAAAVAAADR290Y2hhYSBMeXJpYSAzIE1vY2sAVElUMgAAABcAAADAIEdlbmVyYXRlZCBTb3VuZCBDbGlwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
      
      return mockBase64Mp3;
    } catch (error) {
      console.error('[MusicGenerationProvider] Gemini Lyria 3 Call Failed:', error);
      throw new Error('Upstream audio generation failed');
    }
  }
}

// ============================================================================
// --- MUSIC SERVICE ---
// ============================================================================
class MusicService {
  constructor() {
    this._db = null;
    this._bucket = null;
  }

  get db() {
    if (!this._db) this._db = getFirestore();
    return this._db;
  }
  set db(v) { this._db = v; }

  get bucket() {
    if (!this._bucket) this._bucket = getStorage().bucket();
    return this._bucket;
  }
  set bucket(v) { this._bucket = v; }


  /**
   * Helper to format current date in YYYY-MM-DD
   */
  _getDateString() {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * Generate music clip and write metadata
   */
  async generateSound(userId, prompt) {
    // 1. Age-gate verification: ageTier must be 4 (adult 18+)
    const userPrivateRef = this.db.collection('users_private').doc(userId);
    const userPrivateDoc = await userPrivateRef.get();
    
    if (!userPrivateDoc.exists) {
      throw new Error('Age verification record not found');
    }
    
    const userPrivateData = userPrivateDoc.data();
    if (userPrivateData.ageTier !== 4) {
      throw new Error('Matching and AI generation features are restricted strictly to adult users (18+)');
    }

    const dateStr = this._getDateString();
    const limitDocRef = this.db.collection('music_generation_limits').doc(`${userId}_${dateStr}`);
    const maxLimit = parseInt(process.env.MUSIC_GENERATIONS_PER_USER_PER_DAY || '5', 10);

    // 2. Race-safe transaction check for rate limit
    let limitDoc = await limitDocRef.get();
    let currentCount = limitDoc.exists ? limitDoc.data().count : 0;
    
    if (currentCount >= maxLimit) {
      const rateLimitError = new Error('Daily generation limit exceeded');
      rateLimitError.status = 429;
      throw rateLimitError;
    }

    // 3. Call Gemini Lyria 3 Provider (stubbed)
    const model = process.env.LYRIA_DEFAULT_MODEL || 'lyria-3-clip-preview';
    let base64Audio;
    try {
      base64Audio = await MusicGenerationProvider.generateMusicClip(prompt, model);
    } catch (err) {
      // Failure Handling: If generation fails, we do NOT increment count
      const genError = new Error('Music generation service failed');
      genError.status = 502;
      throw genError;
    }

    // 4. Successful generation! Upload to Storage & write Firestore doc
    const soundId = uuidv4();
    const storagePath = `sounds/${soundId}.mp3`;
    const file = this.bucket.file(storagePath);
    const buffer = Buffer.from(base64Audio, 'base64');

    await file.save(buffer, {
      metadata: {
        contentType: 'audio/mp3',
        metadata: {
          creatorId: userId
        }
      }
    });

    const soundDoc = {
      soundId,
      creatorId: userId,
      prompt: prompt.substring(0, 300),
      model: 'lyria-3-clip',
      storagePath,
      durationSec: 30, // Default duration for lyria-3-clip-preview
      lyrics: null,
      usageCount: 0,
      createdAt: FieldValue.serverTimestamp(),
      visibility: 'public' // Default to public library visibility
    };

    await this.db.collection('sounds').doc(soundId).set(soundDoc);

    // 5. Transactionally increment generation count
    await this.db.runTransaction(async (transaction) => {
      const doc = await transaction.get(limitDocRef);
      const count = doc.exists ? doc.data().count : 0;
      if (count >= maxLimit) {
        throw new Error('Daily generation limit exceeded during atomic save');
      }
      transaction.set(limitDocRef, {
        count: count + 1,
        lastGeneratedAt: FieldValue.serverTimestamp()
      }, { merge: true });
    });

    // Get signed URL for return
    const signedUrl = await this.getSignedPlaybackUrl(soundId);
    return {
      ...soundDoc,
      createdAt: new Date(),
      playbackUrl: signedUrl
    };
  }

  /**
   * Generates a signed playback URL (reusing existing Vybz video signing config)
   */
  async getSignedPlaybackUrl(soundId) {
    const soundRef = this.db.collection('sounds').doc(soundId);
    const soundDoc = await soundRef.get();
    
    if (!soundDoc.exists) {
      const notFoundErr = new Error('Sound not found');
      notFoundErr.status = 404;
      throw notFoundErr;
    }

    const storagePath = soundDoc.data().storagePath;
    const file = this.bucket.file(storagePath);

    // Reuse the exact long-lived expiration approach used for Vybz video playback (03-09-2491)
    const [signedUrl] = await file.getSignedUrl({
      action: 'read',
      expires: '03-09-2491'
    });

    return signedUrl;
  }

  /**
   * Paginated sound library query
   */
  async listLibrary(sort, cursor, limit = 20) {
    let query = this.db.collection('sounds')
      .where('visibility', '==', 'public');

    if (sort === 'trending') {
      query = query.orderBy('usageCount', 'desc').orderBy('createdAt', 'desc');
    } else {
      query = query.orderBy('createdAt', 'desc');
    }

    if (cursor) {
      const cursorDoc = await this.db.collection('sounds').doc(cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    query = query.limit(parseInt(limit, 10));
    const snapshot = await query.get();
    
    const sounds = [];
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const signedUrl = await this.getSignedPlaybackUrl(doc.id);
      sounds.push({
        ...data,
        createdAt: data.createdAt.toDate(),
        playbackUrl: signedUrl
      });
    }

    return sounds;
  }

  /**
   * Attach sound to post and increment count
   */
  async attachSoundToPost(userId, postId, soundId) {
    // 1. Verify sound exists and is public or owned by userId
    const soundRef = this.db.collection('sounds').doc(soundId);
    const soundDoc = await soundRef.get();
    
    if (!soundDoc.exists) {
      const notFoundErr = new Error('Sound not found');
      notFoundErr.status = 404;
      throw notFoundErr;
    }

    const soundData = soundDoc.data();
    if (soundData.visibility !== 'public' && soundData.creatorId !== userId) {
      const forbiddenErr = new Error('Forbidden to attach private sound');
      forbiddenErr.status = 403;
      throw forbiddenErr;
    }

    // 2. Verify post exists
    const postRef = this.db.collection('posts').doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      const notFoundErr = new Error('Post not found');
      notFoundErr.status = 404;
      throw notFoundErr;
    }

    // 3. Atomically update post with soundId and increment usageCount on sound
    const batch = this.db.batch();
    batch.update(postRef, { soundId: soundId });
    batch.update(soundRef, { usageCount: FieldValue.increment(1) });
    
    await batch.commit();
  }
}

module.exports = new MusicService();
