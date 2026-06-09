import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin
# We use the default credentials since we are running in an environment with access
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()

PRIVATE_FIELDS = [
    'email', 'walletBalance', 'inviteCode', 'joinedWithCode', 'inviteLimit', 
    'invitesUsed', 'remainingInvites', 'deviceId', 'invitedUsers', 'totalInvites', 
    'isInviteRewardClaimed', 'phoneNumber', 'gender', 'birthday', 'isPrivate', 
    'showActivityStatus', 'pushNotificationsEnabled', 'isTwoFactorEnabled', 
    'fcmToken', 'isLimitedUser', 'lastUsernameUpdate'
]

def migrate_users():
    users_ref = db.collection('users')
    users = users_ref.stream()
    
    count = 0
    for user in users:
        uid = user.id
        data = user.to_dict()
        
        private_data = {}
        fields_to_remove = []
        
        for field in PRIVATE_FIELDS:
            if field in data:
                private_data[field] = data[field]
                fields_to_remove.append(field)
        
        if private_data:
            print(f"Migrating {uid}...")
            # 1. Write to users_private
            db.collection('users_private').document(uid).set(private_data, merge=True)
            
            # 2. Remove from users
            # We use sentinel for deletion
            update_payload = {field: firestore.DELETE_FIELD for field in fields_to_remove}
            users_ref.document(uid).update(update_payload)
            count += 1
            
    print(f"Migration complete. {count} users processed.")

if __name__ == "__main__":
    migrate_users()
