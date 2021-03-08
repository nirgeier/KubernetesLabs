const
  port = process.env.port || 5050,
  http = require('http'),
  url = require("url"),
  os = require('os'),
  content = process.env.SERVER_NAME || "Hello world";

const requestHandler = (request, response) => {
  const path = url.parse(request.url).pathname;

  if (path == "/failsometimes") {
    if (Math.floor((Math.random() * 3)) == 0) {
      response.statusCode = 500;
    }
  }

  response.end(`${content} requested from ${url.parse(request.url).pathname} on ${os.hostname()} with code ${response.statusCode}`);
};

http.createServer(requestHandler).listen(port, (err) => {
  if (err) {
    return console.log('Error while trying to create server', err);
  }

  console.log(`server is listening on http://127.0.0.1:${port}`);
});