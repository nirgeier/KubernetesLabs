// content of index.js
const
    os = require('os'),
    dns = require('dns'),
    url = require('url'),
    http = require('http'),
    utils = require('./Utils'),
    port = process.env.port || 5050,
    request = require('request'),
    proxyUrl = process.env.PROXY_URL_TO_SERVE || "https://raw.githubusercontent.com/nirgeier/KubernetesLabs/master/Labs/10-Istio/demo-services/mock-data/external-mock1.txt";

/**
 * This is the requestHandler which will process the requests
 * @param {*} request 
 * @param {*} response 
 */
function requestHandler(request, response) {

    const
        path = url.parse(request.url).pathname,
        start = new Date().getTime();
    request(proxyUrl + (path == "/" ? "" : path),
        (err, res, body) => {
            const duration = new Date().getTime() - start;
            response.end(`Proxying reply: ${err ? err.toString() : body} - Took ${duration} milliseconds${os.EOL}`);
        });
}

http.createServer(requestHandler)
    .listen(port, (err) => {
        if (err) {
            return console.log('Error while trying to create server', err);
        }
        console.log(`server is listening on http://127.0.0.1:${port}`);
    });
