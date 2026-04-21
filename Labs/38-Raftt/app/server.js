const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// GET /status - Health check with memory usage
app.get('/status', (req, res) => {
  const memUsage = process.memoryUsage();
  res.json({
    service: 'raftt-lab-backend',
    status: 'healthy',
    uptime: process.uptime(),
    memory: {
      rss: `${Math.round(memUsage.rss / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
    },
  });
});

// POST /calculate - Arithmetic endpoint (contains a deliberate bug)
app.post('/calculate', (req, res) => {
  try {
    const { a, b, operation } = req.body;

    if (a === undefined || b === undefined || !operation) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Missing required fields: a, b, operation',
      });
    }

    let result;
    switch (operation) {
      case 'add':
        result = a + b;
        break;
      case 'subtract':
        result = a - b;
        break;
      case 'multiply':
        result = a * b;
        break;
      case 'divide':
        // BUG: No guard against division by zero!
        // This will produce Infinity or crash depending on input types
        result = a / b;
        if (!isFinite(result)) {
          throw new Error('Cannot divide by zero... or can we?');
        }
        break;
      default:
        return res.status(400).json({
          error: 'Bad Request',
          message: `Unknown operation: ${operation}. Use: add, subtract, multiply, divide`,
        });
    }

    res.json({ a, b, operation, result });
  } catch (err) {
    res.status(500).json({
      error: 'Internal Server Error',
      message: err.message,
    });
  }
});

// GET /info - Environment and version info
app.get('/info', (req, res) => {
  res.json({
    version: '1.0.0',
    nodeEnv: process.env.NODE_ENV || 'production',
    logLevel: process.env.LOG_LEVEL || 'info',
    ...(process.env.FEATURE_FLAG_V2 && { featureFlagV2: process.env.FEATURE_FLAG_V2 }),
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on port ${PORT}`);
});
