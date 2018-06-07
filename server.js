var http = require('http')

var port = 80

var server = http.createServer(function (request, response) {
  response.writeHead(200, {'Content-Type': 'text/html'});
  response.write('<style type="text/css">body {background-color:'+process.env.BACKGROUND_COLOR+';}</style>');
  response.write('<h1>A fancy website</h1>');
  response.write('<p>Hello Azure Friday</p>');
  response.write('<p><b>Version:</b> '+process.env.NODE_VERSION+'</p>');
  response.end();
})

server.listen(port)

console.log('Server running at http://localhost:' + port)
