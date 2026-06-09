# Privacy Policy for GOTCHAA

**Version 3.0 — May 2026**  
**Effective Date:** May 21, 2026  
**Last Updated:** May 21, 2026

Welcome to GOTCHAA. This Privacy Policy explains how GOTCHAA ("we", "us", "our") collects, uses, stores, shares, and protects personal data when you use the GOTCHAA mobile application and related services (the "Platform").

This policy is designed to meet requirements under the EU General Data Protection Regulation (GDPR), UK GDPR, California Consumer Privacy Act (CCPA/CPRA), India's Digital Personal Data Protection Act (DPDPA) 2023, Brazil's LGPD, Canada's PIPEDA, Australia's Privacy Act, and other applicable laws.

## 1. Who We Are

**Data Controller:** GOTCHAA  
**Privacy:** privacy@gotchaa.com  
**Data Protection Officer:** dpo@gotchaa.com  
**Support:** help.gotchaa.com

## 2. Information We Collect

We collect only data necessary to operate the Platform, as reflected in our application code and infrastructure.

### 2.1 Information You Provide

| Category | Examples | Purpose |
|----------|----------|---------|
| Account | Email, password (via Firebase Auth), display name, username | Account creation and authentication |
| Profile | Photo, bio, language preferences, invite code | Profile and social features |
| Content | Posts, comments, chat messages, Vybz videos | Platform functionality |
| Age verification | Date of birth (stored in `users_private`) | Age gating and compliance |
| Support | Emails or messages you send us | Customer support |
| Reports | Report reasons and context you submit | Trust and safety |

### 2.2 Information Collected Automatically

| Category | Examples | Legal basis / consent |
|----------|----------|----------------------|
| Device & app | OS, app version (`package_info_plus`), device identifiers | Legitimate interest / contract |
| Crash diagnostics | Stack traces, crash logs (Firebase Crashlytics) | Legitimate interest (app stability) |
| Usage analytics | Feature usage, session events (Firebase Analytics) | **Consent required** — disabled until you opt in |
| Performance | Load times, traces (Firebase Performance) | **Consent required** |
| Push tokens | FCM device token | Contract / legitimate interest |
| Logs | Timestamps, error metadata | Security and operations |

We do **not** collect precise GPS location by default. Location may be requested only when you use features that need it (e.g., certain third-party service flows) and only with device permission.

### 2.3 Information from Third Parties

- **Google / Apple Sign-In:** Name, email, profile photo if you use social login  
- **Firebase (Google):** Authentication, database, storage, messaging infrastructure  
- **Google Gemini API:** See Section 8 — only when you use AI features  

### 2.4 What We Do NOT Collect from Third-Party Sessions

When you open third-party websites or services (via your device's external browser or an in-app browser view), **GOTCHAA does not collect, access, or store** your browsing activity, cookies, passwords, or transactions on those sites. Those sessions are governed by the third party's own policies.

## 3. Conversation Security (Not Full End-to-End Encryption)

**Important:** GOTCHAA does **not** claim that all messages are end-to-end encrypted such that we can never access them.

GOTCHAA offers **optional conversation encryption** for some chats:

- **Cryptography:** X25519 key agreement and AES-256-GCM  
- **Key storage:** Private keys are stored in your device's secure storage (`flutter_secure_storage`)  
- **Public keys:** Public identity keys may be stored in Firestore to enable key exchange  
- **Encrypted content:** When encryption is enabled, message bodies may be stored as ciphertext in Firestore  

**Limitations:**

- Encryption may be **disabled** for some messages or features (e.g., notification previews, certain chat modes)  
- Metadata (sender, receiver, timestamps, chat IDs) is still processed by our servers  
- We cannot guarantee that all historical messages were encrypted  
- Backups, reports, and legal processes may involve decrypted or plaintext content where applicable  

See our [Security Settings] in-app for key management options.

## 4. Virtual Economy (Karma)

GOTCHAA includes a **Karma** reputation system:

- Karma is a **virtual, non-monetary** engagement score  
- Karma has **no cash value** and cannot be redeemed for money, cryptocurrency, or goods  
- Karma balances are stored in your user profile on our servers  
- We may adjust Karma for abuse, fraud, or policy violations  

## 5. How We Use Your Information

- Provide and maintain the Platform (chat, feed, Vybz, VibeTalk, mini-apps)  
- Authenticate users and prevent fraud  
- Enforce Terms, Community Guidelines, and safety policies  
- Send service notifications (with your settings)  
- Improve the app (analytics and performance, **with consent**)  
- Comply with law and respond to valid legal requests  

We do not sell your personal information. See Section 12 (CCPA).

## 6. Legal Bases (GDPR / UK / LGPD / DPDPA)

| Processing | Legal basis |
|------------|-------------|
| Account & core features | Contractual necessity |
| Security, abuse prevention | Legitimate interests |
| Crash reporting | Legitimate interests |
| Analytics & performance | Consent |
| Marketing (if any) | Consent |
| Legal compliance | Legal obligation |

You may withdraw consent anytime in **Settings → Privacy & Data** without affecting lawfulness of prior processing.

## 7. Data Retention

Retention follows our Firestore and application configuration:

| Data type | Retention period |
|-----------|------------------|
| Chat messages | **24 hours** from send — each message includes an `expiresAt` timestamp; expired messages are deleted or hidden |
| Reported content | Up to **30 days** for safety investigations |
| Account & profile | Until you delete your account, then removed per deletion workflow |
| Deletion requests | Processed within **30 days**; records retained only as legally required |
| Crash logs (Crashlytics) | Per Google's default retention (typically 90 days) |
| Analytics (if consented) | Per Firebase defaults; we minimize identifiable retention |
| `users_private` (age, legal acceptance) | Until account deletion |
| Invite / Karma data | Life of account |

After account deletion, we delete or anonymize personal data within **90 days**, except where law requires longer retention (e.g., fraud records, legal holds).

## 8. Google Gemini AI

When you use **GOTCHAA AI Assistant** (floating overlay or Gemini chat):

| Sent to Google | Not sent |
|--------------|----------|
| Your prompt text and conversation history in that session | Your password or payment data |
| System instruction (Gotchaa-only scope) | Full chat history with other users |
| Model identifier (`gemini-3-flash-preview`) | Photos/files unless you attach them in a future feature |

- Requests go directly from the app to **Google's Generative Language API** using a build-time API key  
- Google's [Privacy Policy](https://policies.google.com/privacy) and [Gemini Terms](https://ai.google.dev/terms) apply  
- Do not submit sensitive personal data, passwords, or others' private information to the AI  
- Content moderation may also send **reported text** to a Cloud Function that uses AI classification  

## 9. Google ML Kit (On-Device)

GOTCHAA uses **Google ML Kit** for on-device processing only:

- Language identification and translation  
- Face detection (camera filters)  
- Selfie segmentation (AR effects)  

**No image or text from these features is sent to Google servers** for ML Kit processing — inference runs locally on your device.

## 10. Sharing and Processors

We share data only with:

| Processor | Purpose |
|-----------|---------|
| Google Firebase | Auth, Firestore, Storage, FCM, Crashlytics, Analytics*, Performance*, App Check |
| Google Gemini API | AI assistant and moderation (when used) |
| Apple / Google | App distribution and in-app purchases (if applicable) |

*Analytics and Performance only with your consent.

International transfers use Standard Contractual Clauses or equivalent safeguards where required.

## 11. Your Rights

### All users
- Access, correction, deletion  
- Withdraw consent (analytics, performance, personalization)  
- Lodge a complaint with your supervisory authority  

### GDPR / UK additional
- Portability, restriction, objection to legitimate-interest processing  

### California (CCPA/CPRA)
- Right to know, delete, correct, opt out of sale (**we do not sell data**), non-discrimination  

### India (DPDPA)
- Information, correction, erasure, grievance redressal, nomination  
- Contact our Grievance Officer in-app (India users)  

**Exercise rights:** privacy@gotchaa.com or **Settings → Privacy & Data → Download my data / Delete my data**

We respond within **30 days** (or as required by law).

## 12. Cookies and Similar Technologies

See our [Cookie Policy] in the Legal Hub. Summary:

- **Strictly necessary:** Auth tokens, secure storage, session state  
- **Analytics / performance:** Firebase — **consent required**  
- **Third-party sites:** When you leave GOTCHAA (external browser or embedded service views), third parties set their own cookies — **not controlled by GOTCHAA**

## 13. Children's Privacy

Minimum ages vary by region (13–18). Users under 13 are blocked. Teen tiers may have restricted features. Parental consent may be required where applicable. Contact privacy@gotchaa.com for child-data requests.

## 14. Security Measures

- TLS in transit; encrypted storage for keys and consent flags  
- Firebase App Check; Firestore security rules  
- Role-based admin access; incident response procedures  
- No method is 100% secure — report issues to security@gotchaa.com  

## 15. Policy Changes

Material changes will update the version number, in-app notification, and **What changed** banner in the Legal Hub. Continued use after notice may require renewed acceptance where legally required.

## 16. Contact

- **privacy@gotchaa.com**  
- **dpo@gotchaa.com**  
- In-app: Settings → Legal  

---

**GOTCHAA — Version 3.0 — May 2026**
