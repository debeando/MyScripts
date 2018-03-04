#!/usr/bin/env sysbench

local function load_data_from_file_to_random(path, type)
  print("Load data from file '" .. path .. "' to 'random' table...")

  local sql   = ""
  local drv   = sysbench.sql.driver()
  local con   = drv:connect()
  local open  = io.open
  local file  = open(path, "rb")

  if not file then return nil end

  for line in io.lines(path) do
    line = string.gsub(line, "\r", "")
    sql  = string.format([[
      INSERT IGNORE INTO random (attribute_value, attribute_type)
      VALUES ("%s", '%s')
    ]], line, type)

    con:query(sql)
  end

  file:close()
end

function prepare()
  local drv = sysbench.sql.driver()
  local con = drv:connect()

  print("Creating table 'random'...")
  con:query(string.format([[
    CREATE TABLE IF NOT EXISTS random (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      attribute_value VARCHAR(64),
      attribute_type  ENUM('FirstName', 'LastName', 'DomainName'),
      PRIMARY KEY (id),
      UNIQUE KEY attribute_uid (attribute_value, attribute_type)
    )
  ]]))

  load_data_from_file_to_random("domainnames.txt", "DomainName")
  load_data_from_file_to_random("firstnames.txt", "FirstName")
  load_data_from_file_to_random("lastnames.txt", "LastName")

  print("Creating table 'users'...")
  con:query(string.format([[
    CREATE TABLE IF NOT EXISTS users (
      id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      email      CHAR(255) NOT NULL,
      username   CHAR(255) NOT NULL,
      first_name VARCHAR(64) NOT NULL,
      last_name  VARCHAR(64),
      status     ENUM('Enable', 'Disable', 'ChangePassword'),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      deleted_at TIMESTAMP
      updated_at TIMESTAMP
      PRIMARY KEY (id),
      UNIQUE KEY email_uid (email),
      UNIQUE KEY username_uid (username)
    )
  ]]))
end

function cleanup()
  local drv = sysbench.sql.driver()
  local con = drv:connect()

  print("Dropping table 'random'...")
  con:query("DROP TABLE IF EXISTS random")

  print("Dropping table 'users'...")
  con:query("DROP TABLE IF EXISTS users")
end

function thread_init()
  drv = sysbench.sql.driver()
  con = drv:connect()
end

function event ()
  con:query("SELECT 1")
end

function thread_done()
  con:disconnect()
end
