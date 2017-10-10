#!/usr/bin/perl
use strict;
use warnings;

my $filename = 'README.md';

open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";

my $is_sql = 0;
while (my $row = <$fh>) {
    chomp $row;
    if ($row =~ m/^```sql$/) {
        $is_sql = 1;
        next;
    }
    if ($row =~ m/^```$/) {
        $is_sql = 0;
        next;
    }
    if ($is_sql) {
        print "$row\n";
    }
}

close($fh);
