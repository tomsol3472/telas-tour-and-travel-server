const http = require('http');

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/packages',
  method: 'GET',
  headers: {
    'Origin': 'http://localhost:3000',
    'Accept': 'application/json, text/plain, */*'
  }
};

const req = http.request(options, res => {
  console.log(`STATUS: ${res.statusCode}`);
  console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
  res.on('data', () => {});
});

req.on('error', e => console.error(e));
req.end();
