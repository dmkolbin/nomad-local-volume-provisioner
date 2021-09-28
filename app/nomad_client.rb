require 'nomad'

class NomadClient
  attr_reader :client
  def initialize(address: "http://127.0.0.1:4646", token:)
    Nomad.configure do |config|
      config.address = address
      config.token   = token
    end
    Nomad.client.instance_variable_set(:"@connection", Nomad.client.setup_connection)
    @client = Nomad.client
  end

  def volume_list(nfs_plugins = [])
    if nfs_plugins.empty?
      Nomad.client.volume.list
    else
      Nomad.client.volume.list.select { |vol| nfs_plugins.include?(vol.plugin_id) }
    end
  end
end
