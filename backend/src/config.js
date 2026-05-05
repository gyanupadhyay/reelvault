module.exports = {
  port: parseInt(process.env.PORT || '3000', 10),
  // Single-user demo. Replace with auth-derived userId when JWT lands.
  defaultUser: 'demo-user',
  staticDir: require('path').join(__dirname, '..', 'public'),
  staticMaxAge: '30d',
  jsonBodyLimit: '1mb',
};
