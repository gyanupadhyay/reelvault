// Composition root. Builds the Express app from middleware + route modules
// and starts listening. Logic lives in routes/ and repositories/.

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { port, staticDir, staticMaxAge, jsonBodyLimit } = require('./config');
const db = require('./db');

const compressionMiddleware = require('./middleware/compression');
const userIdMiddleware = require('./middleware/userId');
const errorHandler = require('./middleware/errorHandler');

const reelsRouter = require('./routes/reels');
const seriesRouter = require('./routes/series');
const progressRouter = require('./routes/progress');
const continueWatchingRouter = require('./routes/continueWatching');

const app = express();

app.use(compressionMiddleware);
app.use(cors());
app.use(express.json({ limit: jsonBodyLimit }));
app.use(morgan('dev'));

// 30d immutable on /static. Filenames are content-stable so the device cache
// can pin them and a re-watch skips the network. ETag covers re-seeds.
app.use(
  '/static',
  express.static(staticDir, {
    maxAge: staticMaxAge,
    immutable: true,
    etag: true,
  })
);

app.use(userIdMiddleware);

app.get('/health', (_req, res) => res.json({ ok: true, driver: db.driver }));

app.use('/reels', reelsRouter);
app.use('/series', seriesRouter);
app.use('/progress', progressRouter);
app.use('/continue-watching', continueWatchingRouter);

app.use(errorHandler);

app.listen(port, () => {
  console.log(`ReelVault backend on :${port} (${db.driver})`);
});
