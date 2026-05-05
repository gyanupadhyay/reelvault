// Final error handler. Logs the full error server-side; returns a generic
// message to the client so we don't leak stack traces / SQL errors / paths.
module.exports = function errorHandler(err, _req, res, _next) {
  console.error(err);
  res.status(500).json({ error: 'internal' });
};
