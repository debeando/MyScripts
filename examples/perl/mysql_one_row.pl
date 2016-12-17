#!/usr/bin/env perl
# -*- mode: perl -*-
# -*- coding: utf-8 -*-
# vi: set ft=perl :

use strict;
require DBI;

my $dbh;
my $sth;
my $dsn = '';
my $sql = '';

$dsn  = ";host=127.0.0.1;port=3306";

eval {
  $dbh = DBI->connect("dbi:mysql:$dsn;", 'root', '',
  {
    RaiseError => 0,
    PrintError => 0,
  }) or die $DBI::errstr . "\n";
};

$sql = "SELECT CONNECTION_ID()";

my ($var) = $dbh->selectrow_array($sql);
print "MySQL Session ID: $var\n";

$dbh->disconnect;
