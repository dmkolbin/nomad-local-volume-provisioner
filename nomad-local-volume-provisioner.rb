#!/usr/bin/ruby

require 'optparse'
require 'logger'
require 'fileutils'
require_relative 'app/nomad_client'

begin
  options = {}
  options[:nomad_addr] = ENV['NOMAD_ADDR']
  options[:nomad_token] = ENV['NOMAD_TOKEN']
  options[:nfs_plugins] ||= []

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: ruby nomad-local-volume-provosioner.rb'

    opts.on('--nomad-addr <addr>', String, 'Nomad address. Default: http://localhost:4646') do |addr|
      options[:nomad_addr] = addr
    end

    opts.on('--nomad-token <token>', String, 'Nomad token') do |secret|
      options[:nomad_token] = secret
    end

    opts.on('--log-level <level>', String, 'Log level: debug/info/warn/error/fatal/unknown') do |level|
      options[:log_level] = level
    end

    opts.on('--polling-rate <frequency>', Integer, 'Time in seconds between polling iterations') do |frequency|
      options[:polling_rate] = frequency
    end

    opts.on('--nfs-plugin <plugin_name>', String, 'NFS plugin name') do |plugin_name|
      options[:nfs_plugins] << plugin_name
    end
  end

  parser.parse!
rescue OptionParser::MissingArgument => e
  puts e.message
  exit 1
end

@log = Logger.new(STDOUT)
@log.level =
  begin
    Object.const_get("Logger::#{options[:log_level].upcase}")
  rescue NameError
    @log.warn("Incorrect log level #{options[:log_level]}\nSet INFO log level")
    Logger::INFO
  end

if options[:nomad_addr].to_s.size.zero?
  @log.warn("Nomad address not set. Use default: http://localhost:4646")
  options[:nomad_addr] = 'http://localhost:4646'
end

@log.debug("Run options: #{options}")

@nomad = NomadClient.new(
  address: options[:nomad_addr],
  token: options[:nomad_token]
)

loop do
  volume_names = @nomad.volume_list(options[:nfs_plugins]).map(&:id)

  @log.debug("Volume names: #{volume_names}")

  volume_names.each do |vol_name|
    volume = @nomad.client.volume.read(vol_name)
    mount_dir = volume.context.share

    if mount_dir.nil?
      @log.debug("Not specified mount dir for #{vol_name}")
      next
    end

    @log.debug("Volume: #{vol_name} mount to dir: #{mount_dir}")

    unless Dir.exist?(mount_dir)
      @log.info("Create directory: #{mount_dir} for volume: #{vol_name}")
      FileUtils.mkdir_p(mount_dir)
    end
  end

  sleep(options[:polling_rate] || 10)
end
