require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const Redis = require('ioredis');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// PostgreSQL connection with retry
const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Redis connection with retry
const redisClient = new Redis(process.env.REDIS_URL, {
  retryStrategy: (times) => Math.min(times * 50, 2000),
});

// Middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Session with Redis
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET || 'fallback-secret',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 1000 * 60 * 60 * 24,
  },
}));

// Routes
app.get('/', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT NOW()');
    res.json({
      message: 'TechStore API is running!',
      database: 'connected',
      time: result.rows[0].now,
      version: '1.0.0',
    });
  } catch (err) {
    res.status(500).json({ error: 'Database connection failed', details: err.message });
  }
});

app.get('/health', async (req, res) => {
  const health = { status: 'healthy', checks: {} };

  try {
    await pgPool.query('SELECT 1');
    health.checks.postgres = 'ok';
  } catch (err) {
    health.status = 'unhealthy';
    health.checks.postgres = err.message;
  }

  try {
    await redisClient.ping();
    health.checks.redis = 'ok';
  } catch (err) {
    health.status = 'unhealthy';
    health.checks.redis = err.message;
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT * FROM products ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/stats', async (req, res) => {
  try {
    const products = await pgPool.query('SELECT COUNT(*) FROM products');
    const users = await pgPool.query('SELECT COUNT(*) FROM users');
    const orders = await pgPool.query('SELECT COUNT(*) FROM orders');
    res.json({
      products: parseInt(products.rows[0].count),
      users: parseInt(users.rows[0].count),
      orders: parseInt(orders.rows[0].count),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`TechStore server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});
