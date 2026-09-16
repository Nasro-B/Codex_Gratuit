const http = require('http');

const LITELLM_PORT = 4100;
const PROXY_PORT = 4101;

function forward(req, res) {
  const options = {
    hostname: '127.0.0.1',
    port: LITELLM_PORT,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: `127.0.0.1:${LITELLM_PORT}` },
  };

  const proxy = http.request(options, (proxyRes) => {
    let body = '';

    if (req.url.split('?')[0].replace(/\/+$/, '') === '/v1/models') {
      proxyRes.on('data', (chunk) => { body += chunk; });
      proxyRes.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (parsed.data && !parsed.models) parsed.models = parsed.data;
          res.writeHead(proxyRes.statusCode, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(parsed));
        } catch (_) {
          res.writeHead(proxyRes.statusCode, proxyRes.headers);
          res.end(body);
        }
      });
      return;
    }

    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxy.on('error', () => {
    if (!res.headersSent) res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end('Proxy error');
  });
  req.pipe(proxy);
}

http.createServer(forward).listen(PROXY_PORT, '127.0.0.1', () => {
  console.log(`Codex Home bridge listening on ${PROXY_PORT}`);
});
