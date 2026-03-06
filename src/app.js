const express = require('express');
const healthRouter = require('./routes/health');

const app = express();
const PORT = 3000;

app.use(healthRouter);

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});

module.exports = app;
