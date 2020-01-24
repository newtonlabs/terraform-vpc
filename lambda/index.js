const https = require('http');

/* Assumes that the event is setup as
{
  "host": "54.174.102.205",  // Static IP of the testserver in outputs
  "path": "/posts/1"         // Whatever you are going to call on the test
}
*/

exports.handler =  async (event) => {
    let options = getOptions(event);
    return httpRequest(options).then((data) => {
        const response = {
            statusCode: 200,
            body: JSON.stringify(data),
        };
        return response;
    });
};

function getOptions(event) {
    // We will need this to load the certs
    // console.log(process.env.LAMBDA_TASK_ROOT);
    return {
        host: event.host,
        path: event.path,
        port: 8080,
        method: 'GET'
    }
}

// Using the primitive https package makes parsing more difficult
// Creating a helper method
function httpRequest(options) {
     return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
          if (res.statusCode < 200 || res.statusCode >= 300) {
                return reject(new Error('statusCode=' + res.statusCode));
            }
            
            // Have to manually chunk the data
            var body = [];
            res.on('data', function(chunk) {
                body.push(chunk);
            });
            res.on('end', function() {
                try {
                    body = JSON.parse(Buffer.concat(body).toString());
                } catch(e) {
                    reject(e);
                }
                resolve(body);
            });
        });
        req.on('error', (e) => {
          reject(e.message);
        });
        // send the request
       req.end();
    });
}