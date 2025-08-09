local rootCAKey = std.extVar("ca_key");
local rootCACrt = std.extVar("ca_crt");
local serverKey = std.extVar("server_key");
local serverCrt = std.extVar("server_crt");

{
  apiVersion: "v1",
  kind: "Secret",
  type: Opaque
  metadata: {
    name: "jenkins-certs",
    namespace: "jenkins",
  },
  data: {
    "root-ca.tls.crt": rootCACrt,
    "root-ca.tls.key": rootCAKey,
    "server.tls.crt": serverCrt,
    "server.tls.key": serverKey,
  },
}
