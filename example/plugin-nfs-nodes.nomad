job "plugin-nfs-nodes" {
  datacenters = ["dc"]
  type = "service"

  group "nodes" {
    count = 4
    task "plugin" {
      driver = "docker"
      config {
        image = "mcr.microsoft.com/k8s/csi/nfs-csi:latest"
        args = [
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=${node.unique.name}",
          "--logtostderr",
          "--v=5",
        ]
        network_mode = "host"
        privileged = true
        mount {
          type = "volume"
          target = "/csi/csi"
          source = "csi-socket"
          readonly = false
        }
      }

      csi_plugin {
        id = "nfs-plugin"
        type = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu = 250
        memory = 128
      }
    }
  }
}
