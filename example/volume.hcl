type = "csi"
id = "example-volume"
name = "example-volume"
plugin_id = "nfs-plugin"

capacity_min = "1MB"
capacity_max = "1GB"

capability {
  access_mode     = "single-node-reader-only"
  attachment_mode = "file-system"
}

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

capability {
  access_mode     = "multi-node-reader-only"
  attachment_mode = "file-system"
}

capability {
  access_mode     = "multi-node-single-writer"
  attachment_mode = "file-system"
}

capability {
  access_mode     = "multi-node-multi-writer"
  attachment_mode = "file-system"
}

context {
  server = "IPADDR_NFS_SERVER"
  share = "/nfs_dir/example"
}