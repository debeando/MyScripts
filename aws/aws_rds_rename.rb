#!/usr/bin/env ruby
# encoding: UTF-8

gem 'aws-sdk', '~> 2'

require 'rubygems'
require 'aws-sdk'
require 'logger'
require 'optparse'

options   = {}
snapshots = []
$logger   = Logger.new(STDOUT)

ARGV.options do |opt|
  begin
    opt.on('-h', '--help', 'Show this help') { puts opt.help; exit 0 }
    opt.on('--instance-from String', 'Instance ID From') do |v|
      options[:instance_from_id] = v
    end
    opt.on('--instance-to String', 'Instance ID To') do |v|
      options[:instance_to_id] = v
    end
    opt.on('--login-path String', 'Login Path') do |v|
      options[:login_path] = v
    end
    opt.on('--database String', 'Database') do |v|
      options[:database] = v
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

def details(instance, login_path, database)
  begin
    $logger.info("Retrieve info from RDS instance: #{instance.db_instance_identifier}")

    {
      status: instance.db_instance_status,
      engine: instance.engine,
      security_groups: security_group(instance),
      parameter_groups: parameter_group(instance),
    }
  rescue Aws::RDS::Errors::DBInstanceNotFound => e
    $logger.error("RDS instance not found: #{instance.db_instance_identifier}")
    exit 1
  end
end

def instance(instance_id)
  $rds.describe_db_instances({
    db_instance_identifier: instance_id,
  }).db_instances.first
end

def endpoint(instance)
  instance.endpoint.address
end

def security_group(instance)
  instance.db_security_groups.map {|sg| sg.db_security_group_name }.sort
end

def parameter_group(instance)
  instance.db_parameter_groups.map {|sg| sg.db_parameter_group_name }.sort
end

def database?(host, login_path, database)
  cmd = %W[mysql
           --login-path=#{login_path}
           --host=#{host} #{database}
           -BNse 'SELECT version();' > /dev/null 2>&1].join(' ')

  $logger.info("Verify existence of a database #{database} on #{host}")
  # $logger.debug(cmd)
  system(cmd)
  $?.exitstatus
end

def tables?(host, login_path, database)
  sql = %W[SELECT COUNT(*)
           FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_SCHEMA = "#{database}";].join(' ')
  cmd = %W[mysql
           --login-path=#{login_path}
           --host=#{host}
           -BNse '#{sql}' 2>/dev/null].join(' ')

  $logger.info("Verify existence of a tables on database #{database} on #{host}")
  # $logger.debug(cmd)

  count = `#{cmd}`
  count.to_i
end

def validate_instance?
  from = details($instance_from, $options[:login_path], $options[:database])
  to   = details($instance_to, $options[:login_path], $options[:database])

  (from == to)
end

def validate_database?
  from = database?(endpoint($instance_from),
                   $options[:login_path],
                   $options[:database])
  to   = database?(endpoint($instance_to),
                   $options[:login_path],
                   $options[:database])

  (from == to)
end

def validate_tables?
  from = tables?(endpoint($instance_from),
                 $options[:login_path],
                 $options[:database])

  to   = tables?(endpoint($instance_to),
                 $options[:login_path],
                 $options[:database])

  return false unless (from.is_a?(Numeric))
  return false unless (from > 0)
  return false unless (to.is_a?(Numeric))
  return false unless (to > 0)

  percentage = ((100 * to) / from)

  $logger.info("Tables from #{from}, Tables to: #{to}, AVG Diff #{percentage}% (OK 75\%-125\%)")

  return true if (percentage >= 75 && percentage <= 125)
  false
end

def rename(instance_id_old, instance_id_new)
  $logger.info("Rename RDS instance: #{instance_id_old} => #{instance_id_new}")

  begin
    $rds.modify_db_instance({
      db_instance_identifier: instance_id_old,
      new_db_instance_identifier: instance_id_new,
      apply_immediately: true,
    })
  rescue Aws::RDS::Errors::DBInstanceAlreadyExists => e
    $logger.error("RDS exist with this name: #{instance_id_new}")
    exit 1
  end

  $logger.info("Wait when instance is ready: #{instance_id_new}")
  begin
    sleep 60

    db_instance_status = $rds.describe_db_instances({
      db_instance_identifier: instance_id_new,
    }).db_instances.first.db_instance_status
  end while db_instance_status != 'available'
end

Aws.config.update({
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                    ENV['AWS_SECRET_ACCESS_KEY'])
})

$rds           = Aws::RDS::Client.new
$options       = options
$instance_from = instance($options[:instance_from_id])
$instance_to   = instance($options[:instance_to_id])

if validate_instance? && validate_database? && validate_tables?
  rename("#{options[:instance_to_id]}", "#{options[:instance_to_id]}-old")
  rename("#{options[:instance_from_id]}", "#{options[:instance_to_id]}")
else
  $logger.info("Imposible to rename RDS instance: #{options[:instance_from_id]} => #{options[:instance_to_id]}")
  exit 1
end
