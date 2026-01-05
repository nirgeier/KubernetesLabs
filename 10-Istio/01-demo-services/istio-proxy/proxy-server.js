// content of index.js
const
    ip = require('ip'),
    os = require('os'),
    http = require('http'),
    request = require('request'),
    port = process.env.port || 5050,
    proxyUrl = process.env.PROXY_URL_TO_SERVE || "https://raw.githubusercontent.com/nirgeier/KubernetesLabs/master/Labs/10-Istio/01-demo-services/mock-data/external-mock1.txt";

/**
 * This is the requestHandler which will process the requests
 * @param {*} request 
 * @param {*} response 
 */
function requestHandler(req, res) {

    const
        path = req.url,
        start = new Date().getTime();

    request(proxyUrl + (path == "/" ? "" : path),
        (err, response, body) => {
            const duration = new Date().getTime() - start;
            res.end(`Proxying reply: ${err ? err.toString() : body} - Took ${duration} milliseconds${os.EOL}`);
        });
}

/**
 * Create the server
 */
http
    .createServer(requestHandler)
    .listen(port, (err) => {
        if (err) {
            return console.log('Error while trying to create server', err);
        }
        console.log(`Proxy Server is listening on http://${ip.address()}:${port}`);
    });
