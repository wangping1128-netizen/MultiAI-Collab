const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const healthRouter = require('../routes/health');

test('GET /health returns status ok with ISO timestamp', async (t) => {
  const app = express();
  app.use(healthRouter);

  const server = http.createServer(app);

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => server.close());

  const address = server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}/health`);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type')?.includes('application/json'), true);

  const body = await response.json();
  assert.equal(body.status, 'ok');
  assert.equal(typeof body.timestamp, 'string');
  assert.equal(Number.isNaN(Date.parse(body.timestamp)), false);
  assert.equal(new Date(body.timestamp).toISOString(), body.timestamp);
});
