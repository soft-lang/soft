#!/usr/bin/perl
use strict;
use warnings;

my $Filename = 'README.md';

open(my $FH, '<:encoding(UTF-8)', $Filename) or die "Could not open file '$Filename' $!";

my $IS_SQL = 0;
while (my $Row = <$FH>) {
    chomp $Row;
    if ($Row =~ m/^```sql$/) {
        $IS_SQL = 1;
        next;
    }
    if ($Row =~ m/^```$/) {
        $IS_SQL = 0;
        next;
    }
    if ($IS_SQL) {
        print "$Row\n";
    }
}

close($FH);
