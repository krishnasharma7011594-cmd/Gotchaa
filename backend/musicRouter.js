const express = require('express');
const musicService = require('./musicService');
const router = express.Router();

// Helper validation functions (lightweight equivalent of NestJS class-validator)
function validatePrompt(req, res, next) {
  const { prompt } = req.body;
  if (!prompt || typeof prompt !== 'string') {
    return res.status(400).json({ error: 'Missing required field: prompt' });
  }
  if (prompt.length > 300) {
    return res.status(400).json({ error: 'Prompt exceeds maximum length of 300 characters' });
  }
  next();
}

function validateAttach(req, res, next) {
  const { postId } = req.body;
  if (!postId || typeof postId !== 'string') {
    return res.status(400).json({ error: 'Missing required field: postId' });
  }
  next();
}

// Routes matching specifications
router.post('/generate', validatePrompt, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { prompt } = req.body;
    const soundDoc = await musicService.generateSound(userId, prompt);
    res.status(201).json(soundDoc);
  } catch (err) {
    console.error('Error generating sound:', err.message);
    const statusCode = err.status || 500;
    res.status(statusCode).json({ error: err.message || 'Internal Server Error' });
  }
});

router.get('/library', async (req, res) => {
  try {
    const { sort, cursor, limit } = req.query;
    const results = await musicService.listLibrary(sort, cursor, limit);
    res.json(results);
  } catch (err) {
    console.error('Error fetching library:', err.message);
    res.status(500).json({ error: 'Failed to retrieve library' });
  }
});

router.get('/:soundId/playback-url', async (req, res) => {
  try {
    const { soundId } = req.params;
    const url = await musicService.getSignedPlaybackUrl(soundId);
    res.json({ url });
  } catch (err) {
    console.error('Error fetching signed playback URL:', err.message);
    const statusCode = err.status || 500;
    res.status(statusCode).json({ error: err.message || 'Internal Server Error' });
  }
});

router.post('/:soundId/attach', validateAttach, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { soundId } = req.params;
    const { postId } = req.body;
    await musicService.attachSoundToPost(userId, postId, soundId);
    res.status(204).send();
  } catch (err) {
    console.error('Error attaching sound to post:', err.message);
    const statusCode = err.status || 500;
    res.status(statusCode).json({ error: err.message || 'Internal Server Error' });
  }
});

module.exports = router;
