#!/usr/bin/env ruby
# encoding: utf-8

# Title           :mysql_data_chunk.rb
# Description     :Chunk Query for data migration.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-05-05
# Version         :0.2

require 'rubygems'
require 'erb'
require 'logger'
require 'mysql2'
require 'optparse'

# Define and set defaults variables:
options = { host: '127.0.0.1',
            username: 'root',
            chunk_size: 10000 }
logger  = Logger.new(STDOUT)

# Set command line for this script:
ARGV.options do |opt|
  begin
    opt.on('-?', '--help', 'Show this help') { puts opt.help; exit 0 }
    opt.on('-h', '--host HOST', String, 'MySQL Host') do |v|
      options[:host] = v
    end
    opt.on('-u', '--username USER', String, 'MySQL User name') do |v|
      options[:username] = v
    end
    opt.on('-p', '--password PASSWORD', String, 'MySQL User password') do |v|
      options[:password] = v
    end
    opt.on('-d', '--database DATABASE', String, 'MySQL Database') do |v|
      options[:database] = v
    end
    opt.on('-t', '--chunk-table NAME', String, 'Chunk table') do |v|
      options[:chunk_table] = v
    end
    opt.on('-s', '--chunk-size SIZE', Integer, 'Chunk size (default 10000)') do |v|
      options[:chunk_size] = v
    end
    opt.on('-f', '--sql-template FILE', String, 'SQL Template File') do |v|
      options[:sql_template] = v
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

# Set security options for MySQL:
options[:init_command] = 'SET SQL_SAFE_UPDATES=1, SQL_BIG_SELECTS=1'

# Connect to MySQL Server:
@conn = Mysql2::Client.new({ host: options[:host],
                             username: options[:username],
                             password: options[:password],
                             database: options[:database],
                             init_command: options[:init_command],
                            })

# Define loop variables:
chunk_table = options[:chunk_table]
chunk_size  = options[:chunk_size]
sql         = "SELECT MAX(id) AS max FROM #{chunk_table}"
row_total   = @conn.query(sql).first['max']
row_delta   = chunk_size * 2
row_total   = row_total + row_delta
chunk_total = row_total / chunk_size

begin
  # Read sql template:
  sql_template = File.read(options[:sql_template])

  for row_id in 1..chunk_total
    # Calculate chunk for template:
    chunk_start = ((row_id * chunk_size) - chunk_size) + 1
    chunk_end   = (row_id * chunk_size)
    percentage  = ((100 * row_id) / chunk_total)

    # Rendering template:
    sql = ERB.new(sql_template).result

    # Execute sql result from template:
    @conn.query(sql)

    # Format info for log:
    chunk_step    = "%.#{chunk_total.to_s.length}i" % row_id
    chunk_start   = "%.#{row_total.to_s.length}i" % chunk_start
    chunk_end     = "%.#{row_total.to_s.length}i" % chunk_end
    affected_rows = "%.#{chunk_size.to_s.length}i" % @conn.affected_rows
    percentage    = "%.3i" % percentage

    # Log progress:
    logger.info("Table: #{chunk_table}, Chunk: #{chunk_step} / #{chunk_total}, Range: #{chunk_start}:#{chunk_end}, Affected: #{affected_rows}, Progress: #{percentage}%")
  end
rescue => e
  logger.error(e)
  exit 1
end
