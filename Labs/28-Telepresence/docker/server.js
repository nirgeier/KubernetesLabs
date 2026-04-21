const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const pty = require("node-pty");
const path = require("path");

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

// Serve static files
app.use(express.static(path.join(__dirname, "public")));

// Serve mkdocs site at /docs/
const docsDir = process.env.DOCS_DIR || path.join(__dirname, "docs");
app.use("/docs", express.static(docsDir));

// Health check
app.get("/health", (req, res) => res.json({ status: "ok" }));

// WebSocket connection handling
wss.on("connection", (ws) => {
  const shell = pty.spawn("/bin/bash", ["--login"], {
    name: "xterm-256color",
    cols: 120,
    rows: 40,
    cwd: "/home/lab",
    env: {
      TERM: "xterm-256color",
      LANG: "en_US.UTF-8",
      HOME: "/home/lab",
      PATH: "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      PS1: "\\[\\033[1;36m\\]telepresence-lab\\[\\033[0m\\]:\\[\\033[1;34m\\]\\w\\[\\033[0m\\]$ ",
    },
  });

  shell.onData((data) => {
    try {
      ws.send(JSON.stringify({ type: "output", data }));
    } catch (e) {
      /* client disconnected */
    }
  });

  shell.onExit(({ exitCode }) => {
    try {
      ws.send(JSON.stringify({ type: "exit", exitCode }));
      ws.close();
    } catch (e) {
      /* already disconnected */
    }
  });

  ws.on("message", (msg) => {
    try {
      const message = JSON.parse(msg);
      switch (message.type) {
        case "input":
          shell.write(message.data);
          break;
        case "resize":
          if (message.cols && message.rows) {
            shell.resize(message.cols, message.rows);
          }
          break;
      }
    } catch (e) {
      /* ignore malformed */
    }
  });

  ws.on("close", () => {
    shell.kill();
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log("");
  console.log("╔═══════════════════════════════════════════════════════╗");
  console.log("║   Telepresence Multi-Cluster Lab - Container Ready   ║");
  console.log("║                                                      ║");
  console.log("║   Clusters: cluster-east, cluster-west               ║");
  console.log(`║   Open:  http://localhost:${PORT}                       ║`);
  console.log("╚═══════════════════════════════════════════════════════╝");
  console.log("");
});
