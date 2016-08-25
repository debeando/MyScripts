#!/usr/bin/ruby
#

require 'rubygems'
require 'bundler'
require 'rake'

# default
desc 'Run all tests.'
task :default => ['check']

# help
desc 'Show available tasks and exit.'
task :help do
  system('rake -T')
end

desc 'Validate syntax.'
task :check do
  @errors = 0
  exclude_paths = ['puppet/modules/apt/**/*',
                   'puppet/modules/stdlib/**/*',
                   'vendor/**/*',
                   'spec/**/*']

  def validate(message, command)
    print message
    output = `#{command}`
    output = output.gsub(/\e\[(\d+;)?(\d+)m/, '').strip
    @errors += 1 unless $?.success?
    puts ($?.success?)? 'OK' : "Fail\n\e[#{31}m#{output}\e[0m"
  end

  files = Dir.glob('**/*').reject{|f| Dir.glob(exclude_paths).include? f}
  files.each do |file|
    if File.file?(file)
      case File.extname(file)
      when '.pp'
        validate("Checking puppet syntax for #{file} ... ",
                 "puppet parser validate #{file} 2>&1")

        validate("Checking puppet style guide for #{file} ... ",
                 "puppet-lint --fail-on-warnings \
                              --no-documentation-check \
                              --no-80chars-check \
                              --no-variable_scope-check #{file}")
      when '.erb'
        validate("Checking puppet template syntax for #{file} ... ",
                 "erb -P -x -T - #{file} | ruby -c 2>&1")
      when '.rb'
        validate("Checking ruby syntax for #{file} ... ",
                 "ruby -c #{file} 2>&1")
      when '.sh'
        validate("Checking shell script syntax for #{file} ... ",
                 "bash -n #{file} 2>&1")
      when '.yaml'
        validate("Checking YAML syntax for #{file} ... ",
                 "ruby -ryaml -e \"YAML.parse(File.open('#{file}'))\"  2>&1")
      when '.eyaml'
        validate("Checking eYAML syntax for #{file} ... ",
                 "ruby -ryaml -e \"YAML.parse(File.open('#{file}'))\"  2>&1")
      end
    end
  end

  exit @errors
end
