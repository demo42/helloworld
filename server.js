var http = require('http')

var port = 80

var server = http.createServer(function (request, response) {
  response.writeHead(200, {'Content-Type': 'text/html'});
  response.write('<style type="text/css">body {background-color:'+process.env.BACKGROUND_COLOR+';}</style>');
  response.write('<h1>Azure Container Registry Build</h1>');
  response.write('<h3>Enabling OS & Framework Patching</h3>');
  response.write('<a href="https://aka.ms/acr/build">https://aka.ms.acr/build</a>');
  response.write('<p>Hello Sajay, officially on the internets!</p>');
  response.write('<p><b>Version:</b> '+process.env.NODE_VERSION+'</p>');
  response.end();
})

server.listen(port)

console.log('Server running at http://localhost:' + port)
