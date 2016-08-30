#!/usr/bin/env perl
# -*- mode: perl -*-
# vi: set ft=perl :

use strict;

my $start = time;
# :
# Do stuff
sleep(1);
# :
my $duration = time - $start;
print "Execution time: ${duration}s\n";
