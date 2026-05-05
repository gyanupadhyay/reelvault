const { defaultUser } = require('../config');

// Reads the user identity off `x-user-id`. The whole app routes through this
// one place so swapping in real auth (JWT verify -> req.userId) only touches
// this file.
module.exports = function userId(req, _res, next) {
  req.userId = req.header('x-user-id') || defaultUser;
  next();
};
