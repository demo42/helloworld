var http = require('http')
var os = require("os");

var port = 80

var server = http.createServer(function (request, response) {
  response.writeHead(200, {'Content-Type': 'text/html'});
 
  response.write('<style type="text/css">body {background-color:'+process.env.BACKGROUND_COLOR+';}</style>');
 
  response.write('<h1>Azure Container Registry Tasks</h1>');
  response.write('<h3>Enabling OS & Framework Patching</h3>');
  response.write('<a href="https://aka.ms/acr/tasks">https://aka.ms/acr/tasks</a></p>');
  response.write('<a href="https://aka.ms/teleport/signup">https://aka.ms/teleport/signup</a></p>');

  response.write('<p>Hello Rejekts-triggered</p>');

  response.write('<p><b>Version:</b> '+process.env.NODE_VERSION+'</p>');
  response.write('<p><b>Background Color:</b> '+process.env.BACKGROUND_COLOR+'</p>');
  response.write('<p><b>HostName:</b> '+os.hostname()+'</p>');
  
  response.end();
})

server.listen(port)

console.log('Server running at http://localhost:' + port)
