const compression = require('compression');

// Skip /static/videos — mp4 is already compressed and gzipping a streamed
// Range response is asking for trouble.
module.exports = compression({
  filter: (req, res) => {
    if (req.path.startsWith('/static/videos')) return false;
    return compression.filter(req, res);
  },
});
