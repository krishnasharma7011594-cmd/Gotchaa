require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const multer = require('multer');

const app = express();
app.use(cors());
app.use(express.json());

// ==========================================
// --- 1. RATE LIMITING MIDDLEWARES ---
// ==========================================

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many API requests, please try again later.' }
});

const chatLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 30, // Limit each IP to 30 requests per minute
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many chat requests. Rate limit is 30/min.' }
});

const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 upload attempts per 15 minutes
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many upload attempts. Rate limit is 10/15min.' }
});

const spotifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Limit each IP to 50 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many Spotify search requests, please try again later.' }
});

const translationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Limit each IP to 50 translation requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many translation requests, please try again later.' }
});

// Apply rate limiters to prefixes
app.use('/api/', apiLimiter);
app.use('/chat/', chatLimiter);
app.use('/upload/', uploadLimiter);
app.use('/spotify/', spotifyLimiter);
app.use('/translation/', translationLimiter);

// SECURITY REQUIREMENT 6: Never expose Client Secret in frontend
const SPOTIFY_CLIENT_ID = process.env.SPOTIFY_CLIENT_ID;
const SPOTIFY_CLIENT_SECRET = process.env.SPOTIFY_CLIENT_SECRET;

if (!SPOTIFY_CLIENT_ID || !SPOTIFY_CLIENT_SECRET) {
  console.warn("WARNING: SPOTIFY_CLIENT_ID or SPOTIFY_CLIENT_SECRET is missing from environment variables.");
}

// Global token caching
let accessToken = null;
let tokenExpiration = 0;

// Centralized Token Manager using Client Credentials Flow
async function getSpotifyToken() {
  if (accessToken && Date.now() < tokenExpiration) {
    return accessToken;
  }

  const auth = Buffer.from(`${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`).toString('base64');
  
  try {
    const response = await axios.post('https://accounts.spotify.com/api/token', 
      'grant_type=client_credentials', 
      {
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );
    
    accessToken = response.data.access_token;
    tokenExpiration = Date.now() + (response.data.expires_in - 300) * 1000;
    
    console.log("SUCCESS: New Spotify Access Token Generated & Cached");
    return accessToken;
    
  } catch (error) {
    const errorDetails = error.response?.data || error.message;
    console.error("FAIL: Failed to generate Spotify token:", errorDetails);
    throw new Error("Spotify Authentication fails: Invalid Client Identifiers.");
  }
}

// ==========================================
// --- 2. FILE UPLOAD PROTECTION CONFIG ---
// ==========================================

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB overall max (matches Video limit)
  }
});

// Magic byte validation helper
const validateMagicBytes = (buffer, mimetype) => {
  if (!buffer || buffer.length < 4) return false;
  
  const hex = buffer.toString('hex', 0, 4).toUpperCase();
  
  if (mimetype.startsWith('image/')) {
    // JPEG: FF D8 FF
    if (hex.startsWith('FFD8FF')) return true;
    // PNG: 89 50 4E 47
    if (hex === '89504E47') return true;
    // GIF: 47 49 46 38
    if (hex === '47494638') return true;
    // WEBP: RIFF ... WEBP
    if (hex === '52494646' && buffer.toString('hex', 8, 12).toUpperCase() === '57454250') return true;
  } else if (mimetype.startsWith('video/')) {
    // MP4 check ftyp (starts with 00 00 00 and then ftyp)
    if (buffer.toString('hex', 4, 8).toUpperCase() === '66747970') return true;
    // WebM / MKV (EBML): 1A 45 DF A3
    if (hex === '1A45DFA3') return true;
  } else if (mimetype === 'application/pdf') {
    // PDF: %PDF (25 50 44 46)
    if (hex === '25504446') return true;
  } else if (
    mimetype === 'application/msword' || 
    mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ) {
    // DOC / DOCX (PK ZIP style): 50 4B 03 04 or legacy D0 CF 11 E0
    if (hex === '504B0304' || hex === 'D0CF11E0') return true;
  } else if (mimetype === 'text/plain') {
    return true; // Plaintext doesn't enforce strict headers, fallback to basic text check
  }
  
  return false;
};

// ==========================================
// --- 3. ENDPOINTS ---
// ==========================================

// API ROUTE: Spotify Search with internal rate limits
app.get('/api/spotify/search', spotifyLimiter, async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ error: "Missing required query parameter: 'q'" });
    }

    const token = await getSpotifyToken();

    const response = await axios.get('https://api.spotify.com/v1/search', {
      params: { 
        q: query, 
        type: 'track', 
        limit: 50
      },
      headers: { 'Authorization': `Bearer ${token}` }
    });

    const items = response.data.tracks.items || [];
    
    const validTracks = items
      .filter(track => track.preview_url !== null && track.preview_url !== undefined)
      .map(track => ({
        id: track.id,
        name: track.name,
        artistName: track.artists ? track.artists.map(a => a.name).join(', ') : 'Unknown',
        albumArtUrl: track.album && track.album.images.length > 0 ? track.album.images[0].url : null,
        previewUrl: track.preview_url
      }))
      .slice(0, 30); 

    res.json({
       _meta: { totalReturned: validTracks.length, query },
       tracks: validTracks 
     });

  } catch (error) {
    console.error("Spotify API request errored out:", error.response?.data || error.message);
    res.status(500).json({ error: "Failed to connect to upstream Spotify API server" });
  }
});

// UPLOAD ENDPOINT: With MIME, Magic bytes, and Size validation
app.post('/upload', uploadLimiter, upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded.' });
  }

  const { mimetype, size, buffer, originalname } = req.file;

  // Determine limits based on target category
  let maxSize = 0;
  let allowedMimes = [];
  let fileCategory = 'documents';

  if (mimetype.startsWith('image/')) {
    maxSize = 10 * 1024 * 1024; // 10MB
    allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    fileCategory = 'images';
  } else if (mimetype.startsWith('video/')) {
    maxSize = 100 * 1024 * 1024; // 100MB
    allowedMimes = ['video/mp4', 'video/webm', 'video/quicktime'];
    fileCategory = 'videos';
  } else {
    maxSize = 20 * 1024 * 1024; // 20MB
    allowedMimes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain'
    ];
    fileCategory = 'documents';
  }

  // 1. File Size Validation
  if (size > maxSize) {
    return res.status(400).json({ 
      error: `File size exceeds the limit. Max allowed for ${fileCategory} is ${maxSize / (1024 * 1024)}MB. (Got ${parseFloat((size / (1024 * 1024)).toFixed(2))}MB)` 
    });
  }

  // 2. MIME Type Validation
  if (!allowedMimes.includes(mimetype)) {
    return res.status(400).json({ error: `Unsupported MIME type for ${fileCategory}: ${mimetype}.` });
  }

  // 3. Magic Byte Validation
  if (!validateMagicBytes(buffer, mimetype)) {
    return res.status(400).json({ error: 'File integrity check failed (magic bytes signature mismatch).' });
  }

  res.status(200).json({ 
    success: true,
    message: 'File successfully uploaded and validated.',
    file: {
      name: originalname,
      category: fileCategory,
      mimetype: mimetype,
      sizeBytes: size
    }
  });
});

// Placeholder Chat API
app.post('/chat/send', chatLimiter, (req, res) => {
  res.json({ success: true, message: 'Message processed under rate-limit constraints.' });
});

// Placeholder Translation API
app.post('/translation/translate', translationLimiter, (req, res) => {
  res.json({ success: true, message: 'Translation processed under rate-limit constraints.' });
});

app.get('/health', (req, res) => {
  res.json({ status: "healthy", service: "Gotcha Spotify & Security Integration API Layer" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
   console.log(`[STARTED] Spotify & Security Backend running on PORT ${PORT}`);
});

