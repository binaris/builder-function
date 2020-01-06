import express from 'express';

const app = express();
app.set('trust proxy', true);

app.get('*', async (_req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({
    hello: 'world'
  }));
});

export default app;
