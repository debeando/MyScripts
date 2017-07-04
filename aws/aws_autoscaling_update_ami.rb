#!/usr/bin/env ruby
# encoding: UTF-8

gem 'aws-sdk', '~> 2'

require 'rubygems'
require 'aws-sdk'

@INSTANCE_NAME    = "qa-employme-web02"
@AMI_NAME         = "qa-employme-web-ami"
@AUTOSCALING_NAME = "qa-employme-web"

Aws.config.update({
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                    ENV['AWS_SECRET_ACCESS_KEY'])
})

autoscaling = Aws::AutoScaling::Client.new

launch_configuration_name = autoscaling.describe_auto_scaling_groups({
  auto_scaling_group_names: [
    @AUTOSCALING_NAME,
  ],
}).auto_scaling_groups[0].launch_configuration_name

# launch_configuration = Aws::AutoScaling::LaunchConfiguration.new
# p launch_configuration.launch_configuration_name

puts "Delete launch configuration on #{@AUTOSCALING_NAME}: #{launch_configuration_name}"

# autoscaling.delete_launch_configuration({
#   launch_configuration_name: launch_configuration_name,
# })

exit(0)

ec2 = Aws::EC2::Client.new()

puts "Search AMI..."
images = ec2.describe_images({
  filters: [
    {
      name: "name",
      values: ["qa-employme-web-ami"],
    },
  ],
})

image_id = images.images.first.image_id

puts "AMI: #{image_id}"
puts "Deregister AMI: #{image_id}"

ec2.deregister_image({
  image_id: image_id,
})

puts "Search Instance..."

instances = ec2.describe_instances({
  filters: [
    {
      name: 'tag:Name',
      values: ['qa-employme-web02']
    },{
      name: 'instance-state-name',
      values: ['running']
    },
  ],
})

instance_id = instances.reservations[0].instances[0].instance_id
instance    = instances.reservations[0].instances[0]

puts "Instance ID: #{instance_id}"
puts "Create new AMI from Instance ID: #{instance_id}"

image = ec2.create_image({
  instance_id: instance_id,
  name: "qa-employme-web-ami",
  description: "qa-employme-web-ami",
})




#instances.each do |instance|
# p instance
#end
