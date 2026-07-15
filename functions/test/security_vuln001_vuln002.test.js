/**
 * Security regression tests for VULN-001 and VULN-002 fixes.
 *
 * VULN-001: users/{userId} Privilege Escalation via role field
 * VULN-002: Moderation functions open to any authenticated user
 *
 * These tests run standalone (not combined with execute_bro_action.test.js)
 * to avoid sinon stub conflicts across test files.
 */

process.env.NODE_ENV = 'test';
const fft = require('firebase-functions-test')();
const chai = require('chai');
const sinon = require('sinon');
const expect = chai.expect;
const admin = require('firebase-admin');
const { Firestore } = require('@google-cloud/firestore');

// Initialize mock firebase app
if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: 'test-project-gotchaa' });
}

// Stub initializeApp safely so index.js doesn't try to re-initialize
if (typeof admin.initializeApp.restore !== 'function') {
    sinon.stub(admin, 'initializeApp');
}

// Setup sandbox for prototype stubbing
const sandbox = sinon.createSandbox();
let collectionStub;

const myFunctions = require('../index.js');

describe('VULN-001 & VULN-002: Security Regression Tests', () => {
    before(() => {
        collectionStub = sandbox.stub(Firestore.prototype, 'collection').callsFake(() => ({
            doc: sinon.stub().returns({
                collection: sinon.stub().returns({
                    doc: sinon.stub().returns({ get: sinon.stub().resolves({ exists: false }) }),
                    get: sinon.stub().resolves({ docs: [], size: 0 }),
                    orderBy: sinon.stub().returnsThis(),
                    limit: sinon.stub().returnsThis(),
                }),
                get: sinon.stub().resolves({ exists: false }),
                set: sinon.stub().resolves(),
                update: sinon.stub().resolves(),
                delete: sinon.stub().resolves(),
            }),
            add: sinon.stub().resolves({ id: 'mock_doc_id' }),
            where: sinon.stub().returnsThis(),
            orderBy: sinon.stub().returnsThis(),
            limit: sinon.stub().returnsThis(),
            get: sinon.stub().resolves({ docs: [], size: 0, forEach: () => {} }),
        }));
    });

    after(() => { sandbox.restore(); });

    describe('getModerationQueue (VULN-002)', () => {
        it('should throw permission-denied for a plain authenticated user (no role claim)', async () => {
            const wrapped = fft.wrap(myFunctions.getModerationQueue);
            try {
                await wrapped({}, { app: {}, auth: { uid: 'user123', token: { role: undefined } } });
                throw new Error('Should have thrown permission-denied');
            } catch (err) {
                expect(err.code).to.equal('permission-denied');
                expect(err.message).to.contain('moderator or admin privileges');
            }
        });

        it('should throw unauthenticated when called with no auth context', async () => {
            const wrapped = fft.wrap(myFunctions.getModerationQueue);
            try {
                await wrapped({}, { app: {}, auth: null });
                throw new Error('Should have thrown unauthenticated');
            } catch (err) {
                expect(err.code).to.equal('unauthenticated');
            }
        });

        it('should allow access when auth token has role == "moderator"', async () => {
            const wrapped = fft.wrap(myFunctions.getModerationQueue);
            const result = await wrapped({}, { app: {}, auth: { uid: 'mod1', token: { role: 'moderator' } } });
            expect(result).to.have.property('queue');
        });

        it('should allow access when auth token has role == "admin"', async () => {
            const wrapped = fft.wrap(myFunctions.getModerationQueue);
            const result = await wrapped({}, { app: {}, auth: { uid: 'admin1', token: { role: 'admin' } } });
            expect(result).to.have.property('queue');
        });
    });

    describe('takeModerationAction (VULN-002)', () => {
        it('should throw permission-denied for a plain authenticated user', async () => {
            const wrapped = fft.wrap(myFunctions.takeModerationAction);
            try {
                await wrapped(
                    { action: 'ban', targetUserId: 'victim' },
                    { app: {}, auth: { uid: 'attacker', token: { role: undefined } } }
                );
                throw new Error('Should have thrown permission-denied');
            } catch (err) {
                expect(err.code).to.equal('permission-denied');
            }
        });

        it('should throw unauthenticated with no auth', async () => {
            const wrapped = fft.wrap(myFunctions.takeModerationAction);
            try {
                await wrapped({ action: 'ban' }, { app: {}, auth: null });
                throw new Error('Should have thrown unauthenticated');
            } catch (err) {
                expect(err.code).to.equal('unauthenticated');
            }
        });
    });

    describe('moderationStats (VULN-002)', () => {
        it('should throw permission-denied for plain auth', async () => {
            const wrapped = fft.wrap(myFunctions.moderationStats);
            try {
                await wrapped({}, { app: {}, auth: { uid: 'user', token: {} } });
                throw new Error('Should have thrown permission-denied');
            } catch (err) {
                expect(err.code).to.equal('permission-denied');
            }
        });
    });

    describe('handleCsamIncident (VULN-002 — admin only)', () => {
        it('should throw permission-denied for moderator role (admin-only endpoint)', async () => {
            const wrapped = fft.wrap(myFunctions.handleCsamIncident);
            try {
                await wrapped(
                    { userId: 'victim' },
                    { app: {}, auth: { uid: 'mod1', token: { role: 'moderator' } } }
                );
                throw new Error('Should have thrown permission-denied');
            } catch (err) {
                expect(err.code).to.equal('permission-denied');
            }
        });

        it('should throw permission-denied for plain auth user', async () => {
            const wrapped = fft.wrap(myFunctions.handleCsamIncident);
            try {
                await wrapped({ userId: 'victim' }, { app: {}, auth: { uid: 'attacker', token: {} } });
                throw new Error('Should have thrown permission-denied');
            } catch (err) {
                expect(err.code).to.equal('permission-denied');
            }
        });
    });
});
