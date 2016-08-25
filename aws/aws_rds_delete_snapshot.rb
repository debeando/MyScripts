#!/usr/bin/env ruby
# encoding: UTF-8

# TODO:
# =====
# - Validar si no existe un snapshot, salir con un exit code 1.
# - Mandar un email si se ha interrumpido algo, por ejemplo al darse el paso
#   anterior.

gem 'aws-sdk', '~> 2'

require 'rubygems'
require 'aws-sdk'
require 'logger'
require 'optparse'

options     = {}
snapshots   = []
logger      = Logger.new(STDOUT)

ARGV.options do |opt|
  begin
    opt.on('-h', '--help', 'Show this help') { puts opt.help; exit 0 }
    opt.on('--instance INSTANCE', 'RDS Instance ID') do |v|
      options[:db_instance_identifier] = v
    end

    opt.parse!

    if options.empty?
      puts opt.help
      exit 1
    end
  rescue => e
    puts e
    exit 1
  end
end

Aws.config.update({
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                    ENV['AWS_SECRET_ACCESS_KEY'])
})

rds = Aws::RDS::Client.new

# Get all snapshots
rds.describe_db_snapshots({
  db_instance_identifier: options[:db_instance_identifier],
}).db_snapshots.each do |snapshot|
  if snapshot.snapshot_type != 'automated'
    snapshots << snapshot.db_snapshot_identifier
  end
end

# Delete all snapshots
if snapshots.count > 0
  snapshots.each do |snapshot|
    logger.info("Deleting snapshot: #{snapshot}")
    rds.delete_db_snapshot({
      db_snapshot_identifier: snapshot
    })
  end
end
