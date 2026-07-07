// backend/test/musicService.test.js
//
// Unit tests for MusicService.
// Strategy: the service is a singleton exported as `new MusicService()`.
// We inject stub `db` and `bucket` properties directly onto the instance
// (no sinon.stub(admin, ...) needed — avoids fighting the modular SDK).

const chai = require('chai');
const expect = chai.expect;
const sinon = require('sinon');

// Initialise a minimal firebase-admin app so getFirestore/getStorage don't
// throw at module-load time.  If already initialised (e.g. watch mode) the
// catch silently skips re-init.
const admin = require('firebase-admin');
try {
  admin.initializeApp({ projectId: 'test-project' });
} catch (_) { /* already initialised */ }

// Now it's safe to require the service (its constructor runs getFirestore() etc.)
const musicService = require('../musicService');

// ── helpers ───────────────────────────────────────────────────────────────────

/** Build a minimal Firestore-document-like stub */
function fakeDoc(exists, dataObj) {
  return { exists, data: () => dataObj };
}

/** Build a collection stub: doc(id) → {get, set, update} */
function fakeCollection(docMap) {
  return {
    doc: (id) => {
      const entry = docMap[id] || {};
      return {
        get: () => Promise.resolve(entry.doc || fakeDoc(false, {})),
        set: entry.set || sinon.stub().resolves(),
        update: entry.update || sinon.stub().resolves(),
      };
    },
    where: () => ({
      orderBy: () => ({
        orderBy: () => ({
          limit: () => ({ get: () => Promise.resolve({ docs: [] }) }),
        }),
        limit: () => ({ get: () => Promise.resolve({ docs: [] }) }),
      }),
    }),
  };
}

// ── tests ─────────────────────────────────────────────────────────────────────

describe('MusicService Unit Tests', () => {
  let savedDb, savedBucket;

  before(() => {
    // Don't touch .db / .bucket here — that would trigger the lazy getter
    // and call the real SDK. We'll just reset the backing fields in afterEach.
  });

  afterEach(() => {
    sinon.restore();
    // Clear the lazily-cached instances so each test starts fresh
    musicService._db = null;
    musicService._bucket = null;
  });

  // ── Test 1: success path ────────────────────────────────────────────────────

  it('should generate sound successfully under limit', async () => {
    const saveStub = sinon.stub().resolves();
    const getSignedUrlStub = sinon
      .stub()
      .resolves(['https://mock-signed-url.mp3']);
    const setStub = sinon.stub().resolves();

    const transactionStub = sinon.stub().callsFake(async (cb) => {
      const tx = {
        get: sinon.stub().resolves(fakeDoc(true, { count: 2 })),
        set: sinon.stub(),
      };
      return cb(tx);
    });

    musicService.db = {
      collection: (name) => {
        if (name === 'users_private') {
          return fakeCollection({
            usr_123: { doc: fakeDoc(true, { ageTier: 4 }) },
          });
        }
        if (name === 'music_generation_limits') {
          return fakeCollection({
            'usr_123_2026-07-07': { doc: fakeDoc(true, { count: 2 }) },
          });
        }
        if (name === 'sounds') {
          return {
            doc: (id) => ({
              set: setStub,
              get: () =>
                Promise.resolve(
                  fakeDoc(true, { storagePath: `sounds/${id}.mp3` })
                ),
            }),
          };
        }
        return fakeCollection({});
      },
      runTransaction: transactionStub,
    };

    musicService.bucket = {
      file: () => ({ save: saveStub, getSignedUrl: getSignedUrlStub }),
    };

    sinon.stub(musicService, '_getDateString').returns('2026-07-07');

    const result = await musicService.generateSound('usr_123', 'A cool summer vibe beat');

    expect(result).to.have.property('soundId');
    expect(result.prompt).to.equal('A cool summer vibe beat');
    expect(result.creatorId).to.equal('usr_123');
    expect(saveStub.calledOnce).to.be.true;
    expect(setStub.calledOnce).to.be.true;
    expect(transactionStub.calledOnce).to.be.true;
  });

  // ── Test 2: rate-limit rejection ────────────────────────────────────────────

  it('should throw 429 when rate limit is exceeded', async () => {
    musicService.db = {
      collection: (name) => {
        if (name === 'users_private') {
          return fakeCollection({
            usr_123: { doc: fakeDoc(true, { ageTier: 4 }) },
          });
        }
        if (name === 'music_generation_limits') {
          return fakeCollection({
            'usr_123_2026-07-07': { doc: fakeDoc(true, { count: 5 }) }, // at limit
          });
        }
        return fakeCollection({});
      },
    };

    sinon.stub(musicService, '_getDateString').returns('2026-07-07');

    try {
      await musicService.generateSound('usr_123', 'Another prompt');
      throw new Error('Should have thrown a 429');
    } catch (err) {
      expect(err.status).to.equal(429);
      expect(err.message).to.include('limit');
    }
  });

  // ── Test 3: generation failure → counter NOT incremented ───────────────────

  it('should NOT increment the counter when generation (storage upload) fails', async () => {
    const saveStub = sinon.stub().rejects(new Error('Storage upload failed'));
    const runTransactionStub = sinon.stub().resolves();

    musicService.db = {
      collection: (name) => {
        if (name === 'users_private') {
          return fakeCollection({
            usr_123: { doc: fakeDoc(true, { ageTier: 4 }) },
          });
        }
        if (name === 'music_generation_limits') {
          return fakeCollection({
            'usr_123_2026-07-07': { doc: fakeDoc(true, { count: 1 }) },
          });
        }
        return fakeCollection({});
      },
      runTransaction: runTransactionStub,
    };

    musicService.bucket = {
      file: () => ({
        save: saveStub,
        getSignedUrl: sinon.stub().resolves(['https://mock.mp3']),
      }),
    };

    sinon.stub(musicService, '_getDateString').returns('2026-07-07');

    try {
      await musicService.generateSound('usr_123', 'Bad prompt');
      throw new Error('Should have thrown');
    } catch (err) {
      // Any 5xx domain error is acceptable
      expect(err.status || 500).to.be.oneOf([500, 502]);
      // Transaction (counter increment) must NOT have fired
      expect(runTransactionStub.called).to.be.false;
    }
  });

  // ── Test 4: attach sound to post ───────────────────────────────────────────

  it('should atomically attach sound to post and increment usageCount', async () => {
    const updateStub = sinon.stub();
    const commitStub = sinon.stub().resolves();

    musicService.db = {
      collection: (name) => ({
        doc: (id) => ({
          get: () => {
            if (name === 'sounds' && id === 'sound_777') {
              return Promise.resolve(
                fakeDoc(true, { visibility: 'public', creatorId: 'usr_123' })
              );
            }
            if (name === 'posts' && id === 'post_888') {
              return Promise.resolve(fakeDoc(true, { userId: 'usr_123' }));
            }
            return Promise.resolve(fakeDoc(false, {}));
          },
        }),
      }),
      batch: () => ({ update: updateStub, commit: commitStub }),
    };

    await musicService.attachSoundToPost('usr_123', 'post_888', 'sound_777');

    expect(updateStub.calledTwice).to.be.true;
    expect(commitStub.calledOnce).to.be.true;
  });
});

