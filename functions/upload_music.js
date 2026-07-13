const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: 'studio-1284397718-50704.firebasestorage.app'
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

const musicLibraryLocalPath = path.join(__dirname, '..', 'music library');

async function uploadMusic() {
    try {
        console.log("Starting upload process...");
        const files = fs.readdirSync(musicLibraryLocalPath);

        let successCount = 0;

        for (const file of files) {
            if (!file.endsWith('.mp3')) continue;

            const filePath = path.join(musicLibraryLocalPath, file);
            const fileName = path.parse(file).name;
            const soundId = uuidv4();

            // The user created a "music library" folder in Firebase storage, so we'll upload there.
            const storagePath = `music library/${file}`;

            console.log(`Uploading ${file}...`);

            // Upload to Firebase Storage
            await bucket.upload(filePath, {
                destination: storagePath,
                metadata: {
                    contentType: 'audio/mpeg',
                },
            });

            // Create record in Firestore 'sounds' collection
            const soundDocRef = db.collection('sounds').doc(soundId);
            await soundDocRef.set({
                soundId: soundId,
                creatorId: 'system',
                prompt: fileName.replace(/_/g, ' '), // Use the filename as the prompt/title without underscores
                model: 'uploaded',
                storagePath: storagePath,
                durationSec: 180, // Default fallback
                usageCount: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                visibility: 'public'
            });

            console.log(`✅ Uploaded completely: ${fileName}`);
            successCount++;
        }

        console.log(`\n🎉 Success! Added ${successCount} songs to the music library.`);
        process.exit(0);

    } catch (error) {
        console.error("Error during upload:", error);
        process.exit(1);
    }
}

uploadMusic();
