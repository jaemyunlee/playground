const express = require('express');
const os = require('os');
const app = express();
const port = 3000;

app.get('/api/test/', (req, res) => res.json({"hostname": os.hostname()}));
app.get('/health/', (req, res) => res.json({"status":"Healthy"}));

app.listen(port, () => console.log(`listen to ${port}.`));