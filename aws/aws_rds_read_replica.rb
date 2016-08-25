#!/usr/bin/env ruby
# encoding: UTF-8

# TODO:
# =====
# - Validar si no se puede crear la read replica, salir con un exit code 1.
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
    opt.on('--source-instance SNAPSHOT', 'RDS Source Instance ID') do |v|
      options[:db_instance_source_identifier] = v
    end
    opt.on('--vpc-security-group SG1,SG2,SG3', Array, 'VPC Security Group ID') do |v|
      options[:vpc_security_group_ids] = v
    end
    opt.on('--security-groups SG1,SG2,SG3', Array, 'Classic Security Group Names') do |v|
      options[:security_groups] = v
    end
    opt.on('--parameter-group PG', 'VPC Parameter Group ID') do |v|
      options[:db_parameter_group_name] = v
    end
    opt.on('--availability-zone ZONE', 'Availability Zone') do |v|
      options[:availability_zone] = v
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

logger.info("Start to create a new RDS read replica from: #{options[:db_instance_source_identifier]}")
logger.info("Create a new RDS read replica: #{options[:db_instance_identifier]}")
rds.create_db_instance_read_replica({
  db_instance_identifier: options[:db_instance_identifier],
  source_db_instance_identifier: options[:db_instance_source_identifier],
  availability_zone: options[:availability_zone]
})

logger.info("Wait when instance is created: #{options[:db_instance_identifier]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:db_instance_identifier],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

db_instance_config = {
  db_instance_identifier: options[:db_instance_identifier],
  db_security_groups: options[:security_groups],
  db_parameter_group_name: options[:db_parameter_group_name],
  vpc_security_group_ids: options[:vpc_security_group_ids],
  backup_retention_period: 1,
  allow_major_version_upgrade: false,
  auto_minor_version_upgrade: false,
  apply_immediately: true,
}

# Remove empty values:
db_instance_config.reject!{|k,v| v.nil?}

logger.info("Modify new RDS: #{options[:db_instance_identifier]}")

# Apply new configuration on instance:
rds.modify_db_instance(db_instance_config)

logger.info("Wait when instance is ready: #{options[:db_instance_identifier]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:db_instance_identifier],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

logger.info("Rebooting instance: #{options[:db_instance_identifier]}")
rds.reboot_db_instance({
  db_instance_identifier: options[:db_instance_identifier],
  force_failover: false,
})

logger.info("Wait when instance is rebooting: #{options[:db_instance_identifier]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:db_instance_identifier],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

logger.info("End to create a new RDS read replica: #{options[:db_instance_identifier]}")
