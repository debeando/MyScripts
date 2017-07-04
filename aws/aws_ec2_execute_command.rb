#!/usr/bin/env ruby
# encoding: UTF-8

gem 'aws-sdk', '~> 2'

require 'rubygems'
require 'aws-sdk'
require 'logger'
require 'net/ssh'
require 'optparse'

Aws.config.update({
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                    ENV['AWS_SECRET_ACCESS_KEY'])
})

filters = [{name: 'instance-state-name', values: ['running']},
           {name: 'tag:Role', values: ['web']}]

ec2 = Aws::EC2::Client.new
instances = ec2.describe_instances(filters: filters)

unless instances.reservations.empty?
  instances.reservations.each do |list|
    instance = list.instances.first
    tags     = list.instances.first.tags

    puts "==> Instance: #{instance.instance_id}"
    puts "--> IP Address: #{instance.private_ip_address}"

    tags.each do |tag|
      puts "--> Tag #{tag.key}: #{tag.value}"
    end

    commands = ["sudo rm -f /var/www/*",
                "sudo rm -rf /var/www/{http,https,qa,prod}",
                "sudo rm -f /etc/httpd/conf.d/{staging,playground,sandbox,qa,prod}*",
                "sudo /etc/puppet/modules/basic/files/deploy.sh --branch=HEYG-368 && sudo crontab -r",
                ]

    begin
      ssh    = Net::SSH.start(instance.private_ip_address, 'deploy')

      commands.each do |command|
        stdout = ssh.exec!(command)
        puts "--> SSH Output: #{stdout}"
      end

      ssh.close
    rescue
      puts "Unable to connect to #{instance.private_ip_address}"
    end
  end
end
