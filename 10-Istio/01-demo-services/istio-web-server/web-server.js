const
  ip = require('ip'),
  os = require('os'),
  http = require('http'),
  port = process.env.port || 5050,
  content = process.env.SERVER_NAME || "Hello world";

const requestHandler = (request, response) => {

  if (request.url == "/failsometimes") {
    if (Math.floor((Math.random() * 3)) == 0) {
      response.statusCode = 500;
    }
  }

  response.end(`WebServer reply: ${content} requested from ${request.url} on ${os.hostname()} with code ${response.statusCode}`);
};

http.createServer(requestHandler)
  .listen(port, (err) => {
    if (err) {
      return console.log('Error while trying to create server', err);
    }

    console.log(`Web Server is listening on http://${ip.address()}:${port}`);
  });