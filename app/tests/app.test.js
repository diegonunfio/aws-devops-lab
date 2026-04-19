'use strict';

const request = require('supertest');
const app = require('../src/index');

describe('Health & Readiness', () => {
  it('returns healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('healthy');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('uptime');
  });

  it('returns ready status', async () => {
    const res = await request(app).get('/ready');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ready');
  });
});

describe('API v1', () => {
  it('returns application metadata', async () => {
    const res = await request(app).get('/api/v1/info');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('name', 'aws-devops-lab-api');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('environment');
    expect(res.body).toHaveProperty('author', 'Diego Nunfio');
  });

  it('returns items list', async () => {
    const res = await request(app).get('/api/v1/items');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
    expect(res.body.total).toBeGreaterThan(0);
  });
});

describe('Metrics endpoint', () => {
  it('returns Prometheus metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('http_requests_total');
  });
});

describe('Error handling', () => {
  it('returns 404 for unknown route', async () => {
    const res = await request(app).get('/this-does-not-exist');
    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('error', 'Not Found');
  });
});