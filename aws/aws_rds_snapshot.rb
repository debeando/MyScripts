#!/usr/bin/env ruby
# encoding: UTF-8

# TODO:
# =====
# - Validar si no se pudo hacer un snapshot, salir con un exit code 1.
# - Mandar un email si se ha interrumpido algo, por ejemplo al darse el paso
#   anterior.

gem 'aws-sdk', '~> 2'

require 'rubygems'
require 'aws-sdk'
require 'logger'
require 'optparse'

options     = {}
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

logger.info("Launch to create a new snapshot for RDS instance: #{options[:db_instance_identifier]}")
rds.create_db_snapshot({
  db_snapshot_identifier: "#{options[:db_instance_identifier]}-#{Time.new.strftime('%Y-%m-%d-%H-%M')}",
  db_instance_identifier: options[:db_instance_identifier],
})

logger.info("Wait when instance finish backup: #{options[:db_instance_identifier]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:db_instance_identifier],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

logger.info("End create snapshot RDS instance: #{options[:db_instance_identifier]}")
