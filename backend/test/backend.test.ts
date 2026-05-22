import request from 'supertest';
import app from '../src/index';

describe('Vysion Backend Orchestrator REST Endpoints', () => {
  
  describe('GET /health', () => {
    it('should return 200 OK health status', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'OK');
      expect(res.body).toHaveProperty('uptime');
    });
  });

  describe('Unauthenticated Requests', () => {
    it('should reject requests without authorization header', async () => {
      const res = await request(app).get('/v1/gemini/token');
      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should reject requests with invalid bearer format', async () => {
      const res = await request(app)
        .get('/v1/gemini/token')
        .set('Authorization', 'InvalidFormat');
      expect(res.status).toBe(401);
    });
  });

  describe('Authenticated Requests (stub mode)', () => {
    it('should mint an ephemeral gemini token', async () => {
      const res = await request(app)
        .get('/v1/gemini/token')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('expiresAt');
    });

    it('should retrieve Stripe subscription status', async () => {
      const res = await request(app)
        .get('/v1/subscription/status')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('active', true);
    });

    it('should query Google Places API proxy', async () => {
      const res = await request(app)
        .post('/v1/places/proxy')
        .set('Authorization', 'Bearer mock-token')
        .send({ query: 'Starbucks Coffee' });

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('name', 'Starbucks Coffee');
    });

    it('should fail places query if query body parameter is missing', async () => {
      const res = await request(app)
        .post('/v1/places/proxy')
        .set('Authorization', 'Bearer mock-token')
        .send({});

      expect(res.status).toBe(400);
    });
  });
});
