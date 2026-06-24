const admin = require('firebase-admin');

// Initialize with application default credentials or local settings if available
// Since we are running on developer machine with logged in firebase CLI:
try {
  admin.initializeApp({
    projectId: 'studio-1284397718-50704'
  });
  
  const db = admin.firestore();
  db.collection('vybz').orderBy('createdAt', 'desc').limit(5).get()
    .then(snapshot => {
      console.log(`Found ${snapshot.size} vybz videos.`);
      snapshot.forEach(doc => {
        console.log(`ID: ${doc.id}`);
        console.log(`Creator: ${doc.data().creatorId}`);
        console.log(`Caption: ${doc.data().caption}`);
        console.log(`URL: ${doc.data().videoUrl}`);
        console.log('-----------------------------------');
      });
      process.exit(0);
    })
    .catch(err => {
      console.error('Error fetching vybz:', err);
      process.exit(1);
    });
} catch (e) {
  console.error('Initialization error:', e);
  process.exit(1);
}
