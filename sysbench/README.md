# sysbench examples #

[Sysbench 1.0](https://github.com/akopytov/sysbench)

## Example Usage ##

### Requirement ###

Create a MySQL database and user for sysbench:

```bash
mysql> CREATE SCHEMA sbtest;
mysql> GRANT ALL PRIVILEGES ON sbtest.* TO sbtest@'localhost' IDENTIFIED BY 'sbtest';
mysql> FLUSH PRIVILEGES;
```

### Run ###

```bash
$ ./transactions.lua \
  --mysql-password=sbtest \
  prepare

$ ./transactions.lua \
  --mysql-password=sbtest \
  --threads=2 \
  --report-interval=1 \
  run

$ ./transactions.lua \
  --mysql-password=sbtest \
  cleanup
```
