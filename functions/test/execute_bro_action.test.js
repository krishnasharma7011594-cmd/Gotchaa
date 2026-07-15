process.env.NODE_ENV = 'test';
const fft = require('firebase-functions-test')();
const chai = require('chai');
const sinon = require('sinon');
const expect = chai.expect;

const admin = require('firebase-admin');
const { Firestore } = require('@google-cloud/firestore');

// 1. Initialize mock firebase app so admin.firestore() has a default app
if (admin.apps.length === 0) {
    admin.initializeApp({
        projectId: 'test-project-gotchaa'
    });
}

// 2. Stub initializeApp safely to prevent the double-initialization error when index.js runs
if (typeof admin.initializeApp.restore !== 'function') {
    sinon.stub(admin, 'initializeApp');
}

// 3. Setup sandbox for prototype stubbing
const sandbox = sinon.createSandbox();
let addStub = sinon.stub().resolves({ id: 'mock_doc_id' });
let collectionStub;

// 4. Import the functions
const myFunctions = require('../index.js');

describe('executeBroAction Cloud Function Unit Tests', () => {
    before(() => {
        collectionStub = sandbox.stub(Firestore.prototype, 'collection').callsFake((name) => {
            if (name === 'bro_failures') {
                return {
                    add: addStub
                };
            }
            // Fallback stub for other collections accessed during load/tests
            return {
                doc: sinon.stub().returns({
                    collection: sinon.stub().returns({
                        doc: sinon.stub().returns({
                            get: sinon.stub().resolves({ exists: false })
                        })
                    })
                }),
                add: sinon.stub().resolves({ id: 'mock_doc_id' })
            };
        });
    });

    beforeEach(() => {
        addStub.resetHistory();
    });

    afterEach(() => {
        // We only restore stubs created inside the tests, not the global setup stubs
    });

    after(() => {
        sandbox.restore();
    });

    it('should throw an error if App Check token is missing', async () => {
        const wrapped = fft.wrap(myFunctions.executeBroAction);
        
        try {
            await wrapped({}, { auth: { uid: 'user123' } });
            throw new Error('Should have failed precondition');
        } catch (error) {
            expect(error.code).to.equal('failed-precondition');
            expect(error.message).to.contain('verified app');
        }
    });

    it('should throw an error if user is unauthenticated', async () => {
        const wrapped = fft.wrap(myFunctions.executeBroAction);
        
        try {
            await wrapped({}, { app: {}, auth: null });
            throw new Error('Should have failed unauthenticated');
        } catch (error) {
            expect(error.code).to.equal('unauthenticated');
        }
    });

    it('should execute cab_booking and return booking info', async () => {
        const wrapped = fft.wrap(myFunctions.executeBroAction);
        const data = {
            action: 'cab_booking',
            data: { destination: 'Connaught Place' }
        };
        const context = {
            app: {},
            auth: { uid: 'user_123' }
        };

        const response = await wrapped(data, context);
        expect(response.success).to.be.true;
        expect(response.result.bookingId).to.contain('UBER-');
        expect(response.result.destination).to.equal('Connaught Place');
        expect(response.tts_response).to.contain('Connaught Place');
    });

    it('should execute food_order and return order info', async () => {
        const wrapped = fft.wrap(myFunctions.executeBroAction);
        const data = {
            intent: 'food_order',
            params: { item: 'Paneer Tikka', restaurant: 'Haldirams' }
        };
        const context = {
            app: {},
            auth: { uid: 'user_123' }
        };

        const response = await wrapped(data, context);
        expect(response.success).to.be.true;
        expect(response.result.orderId).to.contain('FOOD-');
        expect(response.result.foodItem).to.equal('Paneer Tikka');
        expect(response.tts_response).to.contain('Paneer Tikka');
    });

    it('should log failure to Firestore and return success:false on absolute failure', async () => {
        const wrapped = fft.wrap(myFunctions.executeBroAction);
        
        // Remove API key from environment to trigger a query crash
        const originalApiKey = process.env.GEMINI_API_KEY;
        delete process.env.GEMINI_API_KEY;
        
        const data = {
            action: 'query',
            data: { query: 'What is the speed of light?' }
        };
        const context = {
            app: {},
            auth: { uid: 'user_fail' }
        };

        try {
            const response = await wrapped(data, context);
            expect(response.success).to.be.false;
            expect(response.result).to.be.null;
            expect(response.tts_response).to.equal("I couldn't complete that. Please try again.");
            
            // Assert Firestore log was written
            expect(addStub.calledOnce).to.be.true;
            const loggedData = addStub.firstCall.args[0];
            expect(loggedData.uid).to.equal('user_fail');
            expect(loggedData.intent).to.equal('query');
            expect(loggedData.errorMessage).to.contain('GEMINI_API_KEY');
        } finally {
            // Restore env API key
            process.env.GEMINI_API_KEY = originalApiKey;
        }
    });
});
