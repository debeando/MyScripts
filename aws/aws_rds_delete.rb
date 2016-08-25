#!/usr/bin/env ruby
# encoding: UTF-8

# TODO:
# =====
# - Validar si no se puede eliminar el RDS, salir con un exit code 1.
# - Mandar un email si se ha interrumpido algo, por ejemplo al darse el paso
#   anterior.

gem 'aws-sdk', '~> 2'

require 'rubygems'
require 'aws-sdk'
require 'logger'
require 'optparse'

options     = {}
db_instance = nil
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

logger.info("Start delete RDS instance: #{options[:db_instance_identifier]}")
begin
  rds.delete_db_instance({
    db_instance_identifier: options[:db_instance_identifier],
    skip_final_snapshot: true,
  })
rescue Aws::RDS::Errors::DBInstanceNotFound => e
  logger.warn("RDS instance not exist: #{options[:db_instance_identifier]}")
  exit 0
end

begin
  logger.info("Wait for deleting instance: #{options[:db_instance_identifier]}")
  begin
    db_instance = rds.describe_db_instances({
      db_instance_identifier: options[:db_instance_identifier],
    }).db_instances

    sleep 60
  rescue Aws::RDS::Errors::DBInstanceNotFound => e
    logger.warn("RDS instance not found: #{options[:db_instance_identifier]}")
    exit 0
  end
end while ! db_instance.nil?

logger.info("End delete RDS instance: #{options[:db_instance_identifier]}")
