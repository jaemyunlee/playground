const express = require('express');
const fetch = require('node-fetch');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    fetch('http://express.jayground.test:3000/api/test/')
        .then(res => res.text())
        .then(data => {
            console.log(`from serviceB ${data}`);
            res.send(data);
        });
});
app.get('/health/', (req, res) => res.json({"status": "Healthy"}));

app.listen(port, () => console.log(`listen to ${port}.`));