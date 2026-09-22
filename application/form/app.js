var express = require('express');
var path = require('path');
var app = express();
var axios = require('axios'); 

require('dotenv').config();

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.set('view engine', 'ejs');

// const BACKEND_URL = process.env.LOCAL_BACKEND_URL || process.env.BACKEND_URL;
const BACKEND_URL = process.env.BACKEND_URL;

app.get('/', function(req, res) {
  res.sendFile(path.join(__dirname + '/public/index.html'));
});

app.post('/success', async function(req, res) {
  try {
        // console.log("Captured Body:", req.body);
        const response = await axios.post(`${BACKEND_URL}/submit`, req.body);
        res.sendFile(path.join(__dirname + '/public/success.html'));
    } catch (error) {
        console.error("Flask is down!");
        res.status(500).json({ error: 'Flask backend unreachable' });
        console.log(error);
    }
});

app.get('/display', async (req, res) => {
    try {
        const response = await axios.get(`${BACKEND_URL}/node_items`);
        
        const items = response.data; 

        res.render('display', { projects: items });
    } catch (error) {
        console.error("Error fetching from Flask:", error);
        res.status(500).send("Backend is not responding.");
    }
});

app.listen(4000, function() {
  console.log('Frontend app listening on port 4000!');
});