import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function triggered when a user revokes consent.
 * Path: users/{uid}/consents/{consentType}
 * 
 * This supports DPDPA 2023 requirement to cease processing data upon consent withdrawal.
 */
export const onConsentRevoked = functions.firestore
    .document('users/{uid}/consents/{consentType}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // Check if consent was revoked (changed from true to false)
        if (previousValue.granted === true && newValue.granted === false) {
            const uid = context.params.uid;
            const consentType = context.params.consentType;

            console.log(`Consent revoked by user ${uid} for type: ${consentType}`);

            // TODO: Implement specific actions based on consent type
            switch (consentType) {
                case 'dataProcessing':
                    // Cease general data processing
                    await ceeseDataProcessing(uid);
                    break;
                case 'marketing':
                    // Unsubscribe from marketing lists
                    await unsubscribeFromMarketing(uid);
                    break;
                case 'locationTracking':
                    // Clear location data
                    await clearLocationData(uid);
                    break;
                case 'analyticsTracking':
                    // Stop tracking analytics
                    await stopAnalyticsTracking(uid);
                    break;
                default:
                    console.log(`No specific action defined for consent type: ${consentType}`);
            }
        }
    });

async function ceeseDataProcessing(uid: string) {
    console.log(`Ceasing data processing for ${uid}`);
    // Implementation would go here
}

async function unsubscribeFromMarketing(uid: string) {
    console.log(`Unsubscribing ${uid} from marketing`);
    // Implementation would go here
}

async function clearLocationData(uid: string) {
    console.log(`Clearing location data for ${uid}`);
    // Implementation would go here
}

async function stopAnalyticsTracking(uid: string) {
    console.log(`Stopping analytics tracking for ${uid}`);
    // Implementation would go here
}
