const
  ip = require('ip'),
  os = require('os'),
  dns = require('dns'),
  cp = require('child_process'),
  fs = require('fs-extra'),
  promisify = require('util').promisify,
  lookup = promisify(dns.lookup),
  exec = promisify(cp.exec);

// https://stackoverflow.com/a/37015387
function isInDocker() {
  const platform = os.platform();
  // Assume this module is running in linux containers
  if (platform === "darwin" || platform === "win32") return false;
  const file = fs.readFileSync("/proc/self/cgroup", "utf-8");
  return file.indexOf("/docker") !== -1;
};

function getIP() {
  return new Promise((resolve, reject) => {
    if (!isInDocker()) {
      return resolve(ip.address());
    }
    lookup(
      "gateway.docker.internal", {
      family: 4,
      hints: dns.ADDRCONFIG | dns.V4MAPPED,
    }).then(info => {
      return resolve(info.address);
    });

  });
};

module.exports = {
  getIP
}
