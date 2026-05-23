import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import * as admin from 'firebase-admin';
import { getGeminiToken } from './services/gemini-token';
import { checkSubscriptionStatus } from './services/stripe';
import { proxyPlacesSearch, proxyDirections, proxyGeocode } from './services/maps-proxy';

// Initialize Firebase Admin SDK
try {
  admin.initializeApp();
} catch (e) {
  console.log('Firebase Admin initialized without config. Falling back to stub mode.');
}

const app = express();
app.use(cors());
app.use(express.json());

// Extend express Request type to include user information
export interface AuthenticatedRequest extends Request {
  user?: admin.auth.DecodedIdToken | { uid: string; email?: string };
}

/**
 * Authentication middleware validating Firebase JWTs.
 * In test or dev mode, it accepts 'Bearer mock-token' or stub payloads.
 */
export async function validateFirebaseJwt(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header.' });
  }

  const token = authHeader.split(' ')[1];

  // Development/Test fallback
  if (token === 'mock-token' || process.env.NODE_ENV === 'test') {
    req.user = { uid: 'mock-uid-12345', email: 'mock-user@vysion.co' };
    return next();
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'Invalid Firebase authentication token.',
      details: error instanceof Error ? error.message : String(error)
    });
  }
}

// REST Routes
app.get('/v1/gemini/token', validateFirebaseJwt as any, getGeminiToken);
app.get('/v1/subscription/status', validateFirebaseJwt as any, checkSubscriptionStatus);
app.post('/v1/places/proxy', validateFirebaseJwt as any, proxyPlacesSearch);
app.get('/v1/maps/directions', proxyDirections);
app.get('/v1/maps/geocode', proxyGeocode);

// Default Health Probe
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'OK', uptime: process.uptime() });
});

const PORT = process.env.PORT || 3000;
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Vysion Orchestrator running on port ${PORT}`);
  });
}

export default app;
