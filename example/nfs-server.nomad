job "nfs-server" {
  type        = "service"
  datacenters = ["dc"]
  constraint {
    attribute = "${node.class}"
    value     = "system"
  }
  group "nfs" {
    network {
      port "nfs_port_2049" {
        static = 2049
      }
      port "nfs_port_111" {
        static = 111
      }
    }
    count = 1
    task "provisioner" {
      driver = "docker"
      config {
        auth {
          username = "test"
          password = "test"
        }
        image = "nomad-local-volume-provisioner:latest" # need build docker image
        privileged = true
        command = "nomad-local-volume-provisioner"
        args = [
          "--nomad-addr", "http://${attr.nomad.advertise.address}",
          "--polling-rate", "10",
          "--main-mount-dir", "/nfs_dir",
          "--log-level", "info",
          "--chmod", "0777"
        ]
        mount {
          type = "bind"
          target = "/nfs_dir"
          source = "/tmp/nfs"
          readonly = false
          bind_options {
            propagation = "shared"
          }
        }
      }
      env {}
      resources {
        cpu    = 512
        memory = 512
      }
    }
    task "server" {
      driver = "docker"
      config {
        image = "itsthenetwork/nfs-server-alpine:12"
        ports = ["nfs_port_2049", "nfs_port_111"]
        privileged = true
        network_mode = "host"
        volumes = [
          "local/etc/exports:/etc/exports"
        ]
        mount {
          type = "bind"
          target = "/nfs_dir"
          source = "/tmp/nfs"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
        mount {
          type = "bind"
          target = "/usr/bin/nfsd.sh"
          source = "/etc/.ansible/csi-nfs/nfsd.sh"
          readonly = true
        }
      }
      env {}
      template {
        data = <<EOH
/nfs_dir *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)
        EOH
        destination = "local/etc/exports"
      }
      resources {
        cpu    = 256
        memory = 256
      }
      service {
        name = "nfs-server"
        tags = [
          "nfs",
          "server"
        ]
        port = "nfs_port_2049"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}