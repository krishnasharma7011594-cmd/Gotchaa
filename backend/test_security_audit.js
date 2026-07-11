const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

if (getApps().length === 0) {
  initializeApp({
    projectId: 'studio-1284397718-50704',
    storageBucket: 'studio-1284397718-50704.firebasestorage.app'
  });
}

const db = getFirestore();

async function runAudit() {
  console.log('--- STARTING FIREBASE SECURITY AUDIT (PRIORITY FIX) ---');
  try {
    // 1. Query users with role == 'admin'
    console.log('Querying users with role == "admin"...');
    const adminUsersSnap = await db.collection('users')
      .where('role', '==', 'admin')
      .get();
    
    console.log(`Found ${adminUsersSnap.size} admin users.`);
    const adminUsers = [];
    adminUsersSnap.forEach(doc => {
      const data = doc.data();
      adminUsers.push({ id: doc.id, username: data.username, displayName: data.displayName, role: data.role });
    });
    console.log('Admin users list:', JSON.stringify(adminUsers, null, 2));

    // 2. Query users with role == 'moderator'
    console.log('Querying users with role == "moderator"...');
    const modUsersSnap = await db.collection('users')
      .where('role', '==', 'moderator')
      .get();
    
    console.log(`Found ${modUsersSnap.size} moderator users.`);
    const modUsers = [];
    modUsersSnap.forEach(doc => {
      const data = doc.data();
      modUsers.push({ id: doc.id, username: data.username, displayName: data.displayName, role: data.role });
    });
    console.log('Moderator users list:', JSON.stringify(modUsers, null, 2));

    // 3. Check moderation actions logs for suspicious activity
    console.log('Querying moderation_actions logs...');
    const modActionsSnap = await db.collection('moderation_actions')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    console.log(`Found ${modActionsSnap.size} recent moderation actions.`);
    const actions = [];
    modActionsSnap.forEach(doc => {
      actions.push({ id: doc.id, ...doc.data() });
    });
    console.log('Recent moderation actions logs:', JSON.stringify(actions, null, 2));

    console.log('--- AUDIT FINISHED ---');
  } catch (error) {
    console.error('Audit failed with error:', error);
  }
}

runAudit();
