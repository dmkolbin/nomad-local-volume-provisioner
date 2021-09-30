job "plugin-nfs-controller" {
  datacenters = ["dc"]
  type        = "service"

  group "controller" {
    task "controller" {
      driver = "docker"
      config {
        image = "mcr.microsoft.com/k8s/csi/nfs-csi:latest"
        args = [
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=contoller",
          "--logtostderr",
          "-v=5",
        ]
        mount {
          type = "volume"
          target = "/csi/csi"
          source = "csi-socket"
          readonly = false
        }
      }

      csi_plugin {
        id = "nfs-plugin"
        type = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu = 250
        memory = 128
      }
    }
  }
}
