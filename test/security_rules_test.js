const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, setLogLevel, serverTimestamp } = require('firebase/firestore');
const fs = require('fs');

let testEnv;

before(async () => {
  // Suppress irrelevant logs
  setLogLevel('error');
  // Load firestore rules
  testEnv = await initializeTestEnvironment({
    projectId: 'gotchaa-test-project',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  // Clear the database between tests
  await testEnv.clearFirestore();
});

after(async () => {
  // Cleanup
  await testEnv.cleanup();
});

// Helper to get an authenticated context
function getAuthedContext(uid, email = 'user@example.com') {
  return testEnv.authenticatedContext(uid, { email });
}
function getAdminContext() {
  return testEnv.authenticatedContext('admin123', { 
    email: 'krishnasharma7011594@gmail.com',
    admin: true,
    role: 'admin'
  });
}
function getUnauthedContext() {
  return testEnv.unauthenticatedContext();
}

describe('Firestore Security Rules', () => {

  // --- GLOBAL / UNMAPPED PATHS ---
  describe('Global Deny All (Zero Trust)', () => {
    it('1. should deny read on unknown collection', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertFails(getDoc(doc(db, 'unknown_collection', 'doc1')));
    });

    it('2. should deny write on unknown collection', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertFails(setDoc(doc(db, 'unknown_collection', 'doc1'), { foo: 'bar' }));
    });
  });

  // --- USERS COLLECTION ---
  describe('Users Collection', () => {
    it('3. should allow any authenticated user to read profiles', async () => {
      const db = getAuthedContext('user2').firestore();
      await assertSucceeds(getDoc(doc(db, 'users', 'user1')));
    });

    it('4. should deny unauthenticated users to read profiles', async () => {
      const db = getUnauthedContext().firestore();
      await assertFails(getDoc(doc(db, 'users', 'user1')));
    });

    it('5. should allow owner to create profile with valid data', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(setDoc(doc(db, 'users', 'user1'), {
        role: 'user',
        displayName: 'Test User',
        username: 'testuser'
      }));
    });

    it('6. should deny owner from elevating role during create', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertFails(setDoc(doc(db, 'users', 'user1'), {
        role: 'admin',
        displayName: 'Test User',
        username: 'testuser'
      }));
    });

    it('7. should deny owner from updating role (role spoofing)', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'users', 'user1'), { role: 'user' });
      });
      const db = getAuthedContext('user1').firestore();
      await assertFails(updateDoc(doc(db, 'users', 'user1'), { role: 'admin' }));
    });

    it('8. should allow admin to delete user', async () => {
      const db = getAdminContext().firestore();
      await assertSucceeds(deleteDoc(doc(db, 'users', 'user1')));
    });
  });

  // --- USERS_PRIVATE COLLECTION ---
  describe('Users Private Data', () => {
    it('9. should allow owner to read private data', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(getDoc(doc(db, 'users_private', 'user1')));
    });

    it('10. should deny non-owner from reading private data', async () => {
      const db = getAuthedContext('user2').firestore();
      await assertFails(getDoc(doc(db, 'users_private', 'user1')));
    });

    it('11. should allow admin to read private data', async () => {
      const db = getAdminContext().firestore();
      await assertSucceeds(getDoc(doc(db, 'users_private', 'user1')));
    });
  });

  // --- CHATS & MESSAGES ---
  describe('Chats & Messages (Participant Only Access)', () => {
    it('12. should allow participant to create chat', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(setDoc(doc(db, 'chats', 'user1_user2'), {
        participants: ['user1', 'user2']
      }));
    });

    it('13. should deny creating chat if self is not in participants', async () => {
      const db = getAuthedContext('user3').firestore();
      await assertFails(setDoc(doc(db, 'chats', 'user1_user2'), {
        participants: ['user1', 'user2']
      }));
    });

    it('14. should allow participant to read chat', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'chats', 'chat1'), { participants: ['user1', 'user2'] });
      });
      const db = getAuthedContext('user2').firestore();
      await assertSucceeds(getDoc(doc(db, 'chats', 'chat1')));
    });

    it('15. should deny non-participant from reading chat', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'chats', 'chat1'), { participants: ['user1', 'user2'] });
      });
      const db = getAuthedContext('user3').firestore();
      await assertFails(getDoc(doc(db, 'chats', 'chat1')));
    });

    it('16. should allow sender to create message in chat', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(setDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1'), {
        senderId: 'user1',
        text: 'hello',
        timestamp: serverTimestamp()
      }));
    });

    it('17. should deny spoofing senderId on message create', async () => {
      const db = getAuthedContext('user2').firestore(); // logged in as user2
      await assertFails(setDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1'), {
        senderId: 'user1', // Trying to spoof user1
        text: 'hello',
        timestamp: serverTimestamp()
      }));
    });

    it('18. should allow participant to read message', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'chats', 'chat1', 'messages', 'msg1'), {
          senderId: 'user1', receiverId: 'user2', text: 'hello'
        });
      });
      const db = getAuthedContext('user2').firestore();
      await assertSucceeds(getDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1')));
    });

    it('19. should deny non-participant from reading message', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'chats', 'chat1', 'messages', 'msg1'), {
          senderId: 'user1', receiverId: 'user2', text: 'hello'
        });
      });
      const db = getAuthedContext('user3').firestore();
      await assertFails(getDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1')));
    });
  });

  // --- POSTS ---
  describe('Posts (Owner Only Write)', () => {
    it('20. should allow owner to create post', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(setDoc(doc(db, 'posts', 'post1'), {
        authorUid: 'user1',
        text: 'My first post',
        createdAt: serverTimestamp()
      }));
    });

    it('21. should deny non-owner from creating post', async () => {
      const db = getAuthedContext('user2').firestore();
      await assertFails(setDoc(doc(db, 'posts', 'post1'), {
        authorUid: 'user1', // spoofing user1
        text: 'My first post',
        createdAt: serverTimestamp()
      }));
    });

    it('22. should allow owner to delete post', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'posts', 'post1'), { authorUid: 'user1' });
      });
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(deleteDoc(doc(db, 'posts', 'post1')));
    });

    it('23. should deny non-owner from deleting post', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'posts', 'post1'), { authorUid: 'user1' });
      });
      const db = getAuthedContext('user2').firestore();
      await assertFails(deleteDoc(doc(db, 'posts', 'post1')));
    });

    it('24. should allow non-owner to update ONLY stats (likesCount)', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'posts', 'post1'), { authorUid: 'user1', likesCount: 0, text: 'Hello' });
      });
      const db = getAuthedContext('user2').firestore();
      await assertSucceeds(updateDoc(doc(db, 'posts', 'post1'), { likesCount: 1 }));
    });

    it('25. should deny non-owner from updating text in post', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'posts', 'post1'), { authorUid: 'user1', likesCount: 0, text: 'Hello' });
      });
      const db = getAuthedContext('user2').firestore();
      await assertFails(updateDoc(doc(db, 'posts', 'post1'), { text: 'Spoofed text' }));
    });
  });

  // --- DATA VALIDATION (String lengths, Timestamp) ---
  describe('Data Validation', () => {
    it('26. should deny creating post without server timestamp', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertFails(setDoc(doc(db, 'posts', 'post1'), {
        authorUid: 'user1',
        text: 'Hello',
        createdAt: new Date() // Client timestamp
      }));
    });

    it('27. should deny creating message with over-length text', async () => {
      const db = getAuthedContext('user1').firestore();
      const longText = 'a'.repeat(1001); // Exceeds 1000 chars limit
      await assertFails(setDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1'), {
        senderId: 'user1',
        text: longText,
        timestamp: serverTimestamp()
      }));
    });
  });

  // --- VIBETALK MATCHING QUEUE ---
  describe('VibeTalk Queue', () => {
    it('28. should allow user to join their own queue', async () => {
      const db = getAuthedContext('user1').firestore();
      await assertSucceeds(setDoc(doc(db, 'vibetalk_queue', 'user1'), {
        uid: 'user1',
        timestamp: serverTimestamp()
      }));
    });

    it('29. should deny user from joining queue as someone else', async () => {
      const db = getAuthedContext('user2').firestore();
      await assertFails(setDoc(doc(db, 'vibetalk_queue', 'user1'), {
        uid: 'user1',
        timestamp: serverTimestamp()
      }));
    });
  });

  // --- SYSTEM ADMIN ACTIONS ---
  describe('Admin Operations', () => {
    it('30. should allow admin to read takedown requests', async () => {
      const db = getAdminContext().firestore();
      await assertSucceeds(getDoc(doc(db, 'takedown_requests', 'req1')));
    });

    it('31. should deny normal user from reading takedown requests of others', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'takedown_requests', 'req1'), { userId: 'user1' });
      });
      const db = getAuthedContext('user2').firestore();
      await assertFails(getDoc(doc(db, 'takedown_requests', 'req1')));
    });
  });

});
