#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use DBD::Pg;
use File::Slurp qw(write_file);

$| = 1;

my $DBH = DBI->connect("dbi:Pg:", '', '', {pg_enable_utf8 => 1}) or die "Unable to connect";

my $View_DOTs = $DBH->prepare('SELECT * FROM soft.View_DOTs');

$View_DOTs->execute();

my $Rows = $View_DOTs->fetchall_arrayref();

foreach my $Row (@$Rows) {
    my $DOTID   = $Row->[0];
    my $Program = $Row->[1];
    my $Phase   = $Row->[2];
    my $DOT     = $Row->[3];
    write_file("./dot/${DOTID}_${Program}_${Phase}.dot", $DOT);
    `dot -Tpdf -o ./dot/${DOTID}_${Program}_${Phase}.pdf ./dot/${DOTID}_${Program}_${Phase}.dot`;
    unlink("./dot/${DOTID}_${Program}_${Phase}.dot");
}

$View_DOTs->finish();

$DBH->disconnect();
