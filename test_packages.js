const http = require('http');
http.get('http://localhost:5000/api/packages', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log(data.substring(0, 1000)));
}).on('error', console.error);
