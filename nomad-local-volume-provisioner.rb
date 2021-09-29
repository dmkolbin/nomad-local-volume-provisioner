#!/usr/bin/ruby

require 'optparse'
require 'logger'
require 'fileutils'
require_relative 'app/nomad_client'

DOCKER_STDOUT = '/proc/1/fd/1'.freeze

begin
  options = {}
  options[:nomad_addr] = ENV['NOMAD_ADDR']
  options[:nomad_token] = ENV['NOMAD_TOKEN']
  options[:nfs_plugins] ||= []
  options[:mount_dirs] ||= []

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

    opts.on('--main-mount-dir <mount_dir>', String, 'Main mount dir') do |mount_dir|
      options[:mount_dirs] << mount_dir
    end
  end

  parser.parse!
rescue OptionParser::MissingArgument => e
  puts e.message
  exit 1
end

@log = Logger.new(DOCKER_STDOUT)
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

  expected_mounts = volume_names.map do |vol_name|
    volume = @nomad.client.volume.read(vol_name)
    mount_dir = volume.context.share

    if mount_dir.nil?
      @log.debug("Not specified mount dir for #{vol_name}")
    else
      @log.debug("Volume: #{vol_name} mount to dir: #{mount_dir}")
    end
  end

  expected_mounts.select! { |em| em.to_s.split('/').size > 1 }
  expected_mounts.map! do |dir|
    str = ''
    dir.split('/').reject(&:empty?).map { |path| str += "/#{path}" }
  end
  expected_mounts.flatten!.uniq!
  expected_mounts.each do |mount_dir|
    next if Dir.exist?(mount_dir)

    @log.info("Create directory: #{mount_dir}")
    FileUtils.mkdir_p(mount_dir)
  end

  dirs = options[:mount_dirs].map { |md| Dir.glob(File.join(md.to_s, '*')) }.flatten.uniq
  dirs.each do |dir|
    next if expected_mounts.include?(dir) || dir.split('/').size < 1

    @log.info("Delete directory: #{dir}")
    FileUtils.rm_rf(dir)
  end

  sleep(options[:polling_rate] || 10)
end
