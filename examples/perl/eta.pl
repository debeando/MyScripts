#!/usr/bin/env perl
# -*- mode: perl -*-
# vi: set ft=perl :

# Cada chunk tarda 2s y hay N chunks, cuanto tarda todo:
#
# 1 * ( 84180 - 79631 ) = 4549
# 1 * ( 4549 ) = 4549
#

my $seconds = 4549;
my $hours   = int( $seconds / (60*60));
my $minutes = int(($seconds - $hours*60*60) / (60));
my $seconds = int( $seconds - ($hours*60*60) - ($minutes*60));

print "$hours:$minutes:$seconds\n";
