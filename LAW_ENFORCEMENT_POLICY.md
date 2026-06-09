# GOTCHAA Law Enforcement Guidelines

**Version 3.0 — May 2026**  
**Effective Date:** May 21, 2026  
**Last Updated:** May 21, 2026

This policy describes how GOTCHAA responds to law enforcement and government requests for user data.

## 1. Legal Process Required

We require valid legal process before disclosing user data, except in emergencies involving imminent danger of death or serious physical injury.

| Request type | Typical requirement |
|--------------|---------------------|
| Basic subscriber info | Subpoena or equivalent |
| Content & communications | Court order / warrant where applicable |
| Real-time interception | Wiretap order as required by law |
| International | Mutual Legal Assistance Treaty (MLAT) or local equivalent |

Send requests to: **legal@gotchaa.com** (encrypted PDF preferred)

## 2. Data We Can Provide

Depending on legal process and technical availability:

| Data | Notes |
|------|-------|
| Account email, username, profile | `users` collection |
| Registration IP / acceptance IP | `users_private` if recorded |
| Public posts, comments | Firestore / Storage |
| Chat messages | May be encrypted; retention **24 hours** default |
| Reports & safety records | Up to **30 days** for investigations |
| VibeTalk metadata | Match times, reports — not full video storage by default |
| Crash logs | Crashlytics (Google) |

We **cannot** decrypt optional E2EE messages without device keys.

## 3. Emergency Requests

For imminent threat to life, law enforcement may email **legal@gotchaa.com** with subject **"EMERGENCY DISCLOSURE REQUEST"** including:

- Agency name and officer contact  
- Nature of emergency  
- Specific data needed  
- Why normal process is insufficient  

We review 24/7 and respond as quickly as practicable.

## 4. User Notice

Unless legally prohibited, we notify users before disclosure and provide time to challenge requests.

## 5. Transparency

We commit to publishing an annual **Transparency Report** (when operational) covering:

- Number of government requests received  
- Number complied with / rejected  
- Emergency disclosure count  

## 6. Preservation Requests

We may preserve data for **90 days** upon valid preservation request pending formal process.

## 7. Contact

legal@gotchaa.com

---

**GOTCHAA — Version 3.0 — May 2026**
