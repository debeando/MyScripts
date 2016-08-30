#!/usr/bin/env perl
# -*- mode: perl -*-
# vi: set ft=perl :

use Time::Piece;

my $format = '%a %b %d %H:%M:%S %Y';
my $date1  = 'Fri Aug 30 02:10:02 2013';
my $date2  = 'Fri Aug 30 02:00:00 2013';

my $diff = Time::Piece->strptime($date1, $format)
         - Time::Piece->strptime($date2, $format);

print "Seconds: $diff\n";

my $seconds = $diff;
my $hours   = int( $seconds / (60*60));
my $minutes = int(($seconds - $hours*60*60) / (60));
my $seconds = int( $seconds - ($hours*60*60) - ($minutes*60));

print "Time: $hours:$minutes:$seconds\n";
