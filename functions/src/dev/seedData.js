// =============================================================================
// DEV-ONLY: Demo seed data for local Firebase emulator.
// These accounts are NOT for production. Do NOT import this file in production
// code paths. Use the seedDemoData Cloud Function (emulator only).
// =============================================================================

/**
 * @typedef {Object} DemoUser
 * @property {string} uid
 * @property {string} email
 * @property {string} password
 * @property {string} displayName
 * @property {string} username
 * @property {string} bio
 * @property {string} photoUrl
 * @property {string} language
 * @property {{ country: string, continent: string, code: string }} nation
 * @property {number} followersCount
 * @property {number} followingCount
 * @property {number} karma
 * @property {string} gender
 * @property {number} ageTier
 * @property {Date} birthday
 */

/** @type {DemoUser[]} */
const DEMO_USERS = [
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

module.exports = { DEMO_USERS };
