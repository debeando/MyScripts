#!/usr/bin/env ruby
# encoding: utf-8

# Title           :mysql_data_merge.rb
# Description     :Merge Diff Data into same row.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-05-05
# Version         :0.2

require 'rubygems'
require 'logger'
require 'mysql2'
require 'optparse'

options = {}
logger  = Logger.new(STDOUT)

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
    opt.on('-t', '--duplicate-table TABLE', String, 'Origin from duplicate rows') do |v|
      options[:duplicate_table] = v
    end
    opt.on('-c', '--duplicate-columns COLUMNS', Array, 'Columns to determin duplicate rows') do |v|
      options[:duplicate_columns] = v
    end
    opt.on('-m', '--merge-tables TABLE', Array, 'Tables to merge') do |v|
      options[:merges_table] = v
    end
    opt.on('-f', '--merge-foraign-key COLUMN', String, 'Foreign Key to merge') do |v|
      options[:merge_foraign_key] = v
    end
    opt.on('-r', '--remove', 'Remove parent duplicates') do |v|
      options[:remove] = v
    end

    opt.parse!

    if options.empty?
      puts opt.help
      exit 1
    end

    mandatory = [:host,
                 :username,
                 :password,
                 :database,
                 :duplicate_table,
                 :duplicate_columns,
                 :merges_table,
                 :merge_foraign_key
               ]
    missing = mandatory.select{ |param| options[param].nil? }
    unless missing.empty?
      puts "Missing options: #{missing.join(', ')}"
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
                           })

columns = options[:duplicate_columns].join('`,`')
                                     .insert(0, 'MD5(CONCAT(`')
                                     .insert(-1, '`))')

options[:merges_table].each do |table|
  sql = "SELECT good, bad
         FROM (
               SELECT MIN(id) AS good, MAX(id) AS bad
               FROM #{options[:duplicate_table]}
               GROUP BY #{columns}
               HAVING COUNT(#{columns}) > 1
               ORDER BY #{columns}
         ) AS duplicates
         WHERE EXISTS (SELECT id
                       FROM #{table}
                       WHERE #{options[:merge_foraign_key]} = bad);"

  rows = @conn.query(sql, :symbolize_keys => true)

  logger.info("Found rows: #{rows.count}")

  rows.each do |row|
    sql = "UPDATE #{table}
              SET #{options[:merge_foraign_key]} = #{row[:good]}
            WHERE #{options[:merge_foraign_key]} = #{row[:bad]};"

    @conn.query(sql)
    logger.info("Merged row id #{row[:bad]} into #{row[:good]} on table #{table}.")
  end
end

if options[:remove]
  sql = "SELECT MAX(id) AS bad
         FROM #{options[:duplicate_table]}
         GROUP BY #{columns}
         HAVING COUNT(#{columns}) > 1
         ORDER BY #{columns}"

  rows = @conn.query(sql, :symbolize_keys => true)

  rows.each do |row|
    sql = "DELETE FROM #{options[:duplicate_table]} WHERE id = #{row[:bad]};"

    @conn.query(sql)
    logger.info("Remove duplicate row id #{row[:bad]} on table #{options[:duplicate_table]}.")
  end
end
