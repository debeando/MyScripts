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

options   = {}
snapshots = []
logger    = Logger.new(STDOUT)

ARGV.options do |opt|
  begin
    opt.on('-h', '--help', 'Show this help') { puts opt.help; exit 0 }
    opt.on('--instance ID', 'New RDS Instance ID') do |v|
      options[:instance_id] = v
    end
    opt.on('--snapshot ID', 'RDS Snapshot Instance ID') do |v|
      options[:snapshot_id] = v
    end
    opt.on('--instance-class NAME', 'RDS Instance Class') do |v|
      options[:instance_class] = v
    end
    opt.on('--vpc-subnet ID', 'VPC Subnet') do |v|
      options[:vpc_subnet] = v
    end
    opt.on('--vpc-security-group SG1,SG2,SG3', Array, 'VPC Security Group ID') do |v|
      options[:vpc_security_group_ids] = v
    end
    opt.on('--security-groups SG1,SG2,SG3', Array, 'Classic Security Group Names') do |v|
      options[:security_groups] = v
    end
    opt.on('--parameter-group NAME', 'Parameter Group ID') do |v|
      options[:parameter_group] = v
    end
    opt.on('--availability-zone NAME', 'Availability Zone') do |v|
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

logger.info("Start to restore RDS instance from snapshot: #{options[:snapshot_id]}")

# Get all snapshots
rds.describe_db_snapshots({
  db_instance_identifier: options[:snapshot_id],
}).db_snapshots.each do |snapshot|
  snapshots << { created_at: snapshot.snapshot_create_time,
                 id:         snapshot.db_snapshot_identifier,
                 type:       snapshot.snapshot_type }
end

if snapshots.count == 0
  logger.error("Impossible to restore, not exist snapshot.")
  exit 1
end

db_snapshot_identifier = snapshots.sort_by{|k, v| v}
                                  .reverse
                                  .first[:id]

# Create a configuration hash:
db_instance_config = {
  db_instance_identifier: options[:instance_id],
  db_snapshot_identifier: db_snapshot_identifier,
  db_instance_class: options[:instance_class],
  db_subnet_group_name: options[:vpc_subnet],
  availability_zone: options[:availability_zone],
  multi_az: false,
  iops: 1000,
  storage_type: 'io1',
}

# Remove empty values:
db_instance_config.reject!{|k,v| v.nil?}

logger.info("Restore from this snapshot: #{db_snapshot_identifier}")
logger.info("Restore RDS Instance: #{options[:instance_id]}")
begin
  rds.restore_db_instance_from_db_snapshot(db_instance_config)
rescue Aws::RDS::Errors::AccessDenied => e
  logger.error("AWS Access Denied.")
  exit 1
rescue Aws::RDS::Errors::DBInstanceAlreadyExists => e
  logger.error("RDS Instance already exists.")
  exit 1
end

logger.info("Wait when instance is created: #{options[:instance_id]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:instance_id],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

logger.info("Modify new RDS: #{options[:instance_id]}")

# Create a configuration hash:
db_instance_config = {
  db_instance_identifier: options[:instance_id],
  vpc_security_group_ids: options[:vpc_security_group],
  db_parameter_group_name: options[:parameter_group],
  db_security_groups: options[:security_groups],
  backup_retention_period: 1,
  allow_major_version_upgrade: false,
  auto_minor_version_upgrade: false,
  apply_immediately: true,
}

# Remove empty values:
db_instance_config.reject!{|k,v| v.nil?}

# Apply new configuration on instance:
rds.modify_db_instance(db_instance_config)

logger.info("Wait when instance is ready: #{options[:instance_id]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:instance_id],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

logger.info("Rebooting instance: #{options[:instance_id]}")
rds.reboot_db_instance({
  db_instance_identifier: options[:instance_id],
  force_failover: false,
})

logger.info("Wait when instance is rebooting: #{options[:instance_id]}")
begin
  sleep 60

  db_instance_status = rds.describe_db_instances({
    db_instance_identifier: options[:instance_id],
  }).db_instances.first.db_instance_status
end while db_instance_status != 'available'

logger.info("End restore RDS instance: #{options[:instance_id]}")
