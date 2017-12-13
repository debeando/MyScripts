#!/usr/bin/perl
use strict;
use Data::Dumper;
use Getopt::Long;

# author:
# - Gavin Towey, 2008 gtowey@gmail.com
# - Nicola Strappazzon, 2017
# todo, add "follow thread" capability
# so we can give a process name or thread id & see
# all activity in sequence for each thread

my %OPTIONS;

if (
  !GetOptions( \%OPTIONS,
    "help",
    "type|t=s",
    "pattern|p=s",
    "preserve-newlines|n",
    "separator|s=s" )
  )
{
  $OPTIONS{'help'}++;
}

if (!defined($OPTIONS{'type'})) {
  $OPTIONS{'type'} = 'query';
} else {
  $OPTIONS{'type'} = lc ($OPTIONS{'type'});
}

my $file = $ARGV[0];

if ( !$file ) {
  print "missing log file name\n";
  $OPTIONS{'help'}++;
}

if ( $OPTIONS{'help'} ) {
  usage();
  exit;
}

main();
exit;

my @LINEBUFFER;

sub get_next_query {
  my ($FH) = shift;
  my ( $query_found, $error, $in_block ) = ( 0, 0, 0 );
  if ($#LINEBUFFER ==0 ) { $in_block = 1; }

  while ( !$query_found && !$error ) {
    $LINEBUFFER[ $#LINEBUFFER + 1 ] = <$FH>;
    if ( !$LINEBUFFER[$#LINEBUFFER] ) {
      return -1;
    }

    if ( !$in_block
      && $LINEBUFFER[$#LINEBUFFER] =~ /^(\d{6} [\d:]{8})?\s+(\d+)\s(\w+)(\s(.*))?/ )
    {    # we have the beginning of a line
      if ( $#LINEBUFFER == 0  ) {    # begin block capture
        $in_block = 1;
      }
    }
    elsif ($in_block) {
      if ( $LINEBUFFER[$#LINEBUFFER] =~ /^(\d{6} [\d:]{8})?\s+(\d+)\s(\w+)(\s(.*))?/ ) {
        if ( $#LINEBUFFER > 0 ) {    #end block
              # return everything up to this statement
          $query_found = '';
          for ( my $i = 0 ; $i < $#LINEBUFFER ; $i++ ) {
            $query_found .= $LINEBUFFER[$i];
          }
          $LINEBUFFER[0] = $LINEBUFFER[$#LINEBUFFER];
          $#LINEBUFFER = 0;
        }
      } else {
      }
    }
    else {
      shift @LINEBUFFER;
    }

  }
  return $query_found;
}

sub main {
  open( FILE, $file );
  my $done = 0;
  while ( !$done ) {
    my $query = get_next_query( \*FILE );

    if ( $query eq -1 ) {
      $done = 1;
    }
    else {
      chomp($query);
      $query =~ /^(\d{6} [\d:]{8})?\s+(\d+)\s(\w+)(\s+(.*))?/s;
      my ($type, $query ) = (lc($3), $5);
      if (!$OPTIONS{'preserve-newlines'}) { $query =~ s/[\r\n]/ /g; }

      if ( $type eq 'connect' ) {
        my ($user, $host, $schema) = ($query =~ /(\w+)\@([\w\.\-\_]+)\son\s(\w+)/g);
        print "USE " . $schema . $OPTIONS{'separator'} . "\n";
      } elsif ( $type eq $OPTIONS{'type'}) {
        if (defined($OPTIONS{'pattern'})) {
          if ( $query =~ /$OPTIONS{'pattern'}/ ) {
            print $query . $OPTIONS{'separator'} . "\n";
          }
        } else {
          print $query . $OPTIONS{'separator'}. "\n";
        }
      }
    }
  }
  close FILE;
}

sub usage {
  print <<EOF;
NAME
  $0 - dump statement from mysql general log format

USAGE
  $0 <options> [log file]

SYNOPISIS
  For the most part, the general log is pretty straighforward,
  except when SQL statements contain newline characters.
  This script takes care of finding those boundaries and
  extracting whole statements.

  Most often some filter is passed to the program in order
  to return only certain types of statements.


OPTIONS

  --help
    Display this screen

  --type=s
   -t
    One of Query or Connect, default is Query

  --pattern=s
   -p
    Regular expression to match statements against.
    Usually something like ^SELECT

  --preserve-newlines
   -n
    Keep original newlines in multiline queries default
    is to make all queries single line.

  -separator=s
   -s
    Add the separator after every query

EOF
exit;
}