#!/usr/bin/perl -w
###############################################################################
use strict;
use Getopt::Long;
my $usage = "Erreur!!  Usage: $0 $!\n";
my $NA = "NA";
###############################################################################
my ($a, $output, $megapathway, $output_meta);
my $nom;
my (%koh, %ref, %gen, %ko, %cog, $phylum, $genus, $koid, $cogid, %met, %met2);
my ($tko, $tt, $tm);

my $options = join(" ", @ARGV);

GetOptions ("correlation=s"           => \$megapathway,   
            "infile=s"                => \$a,
            "output=s"                => \$output_meta,
            ) or die("pbm files $usage");

my $md5 = `md5sum $0`;
chomp($md5);
my $audit_trail = "# ".localtime()."\n"."# user: ".$ENV{"USER"}."\n"."# directory:".$ENV{'PWD'}."\n"."# cmd: ".$0." ".$options."\n# $md5";


if (! $megapathway) {
    print "No correlation table\n $usage\n";
    exit;
}
if (! $a) { print "No abundance table\n $usage\n"; exit;}

print localtime()."\t"."pivot_table - Step 1/4\n";
###############################################################################
### correlation ###
###############################################################################
open (FILE1b, $megapathway) or die "pbm pathway file: $usage";
while (<FILE1b>) {
    chomp;
    my @tab = split ("\t", $_);
    my ($ko,$path) =~ /ko:(\S+)\s+(\S+)/;
    $met{$ko}{$path} = 1;
}

close FILE1b;

###############################################################################
#### Parse abundance table ###
###############################################################################
print localtime()."\t"."pivot_table - Step 2/4\n";

my @samples;

open (FILE2, $a) or die "pbm FILE2 abun table: $usage";
while (<FILE2>) {
    if ($_ !~ /^#/) {
        chomp;
        my @tab = split ("\t", $_);
        if ($tab[0] eq "GeneID") {
            for my $i (3..$#tab){
                push (@samples, $tab[$i])
            }
        }
        else{
            my $gene = $tab[0];
            my $ko = $tab[1];
            for my $i (3..$#tab){
                my $s = $samples[$i-3];
                my $v = $tab[$i];
                $ko{$ko}{$s} += $v;
            }
        }
    }
}

close FILE2;

###############################################################################
### Writing ###
###############################################################################
print localtime()."\t"."pivot_table - Step 3/4\n";
###############################################################################
open(W3, ">$output_meta") or die "pbm output_met: $usage";

print W3 "ko\t".join ("\t", @samples)."\n";

foreach my $m (keys %ko){
    my @valuesM;
    foreach my $s (@samples){
        if ($ko{$m}{$s}) {
            push (@valuesM, $ko{$m}{$s});
        }
        else{
            push (@valuesM, "0");
        }
    }
    $tm++;
    print W3 $m."\t";
    print W3 join ("\t", @valuesM)."\n";
}
close W3;

###############################################################################
print localtime()."\t"."pivot_table - Step 4/4\n";

print "Number of pathways = $tm\n";

