#!/usr/bin/perl -w
###############################################################################
# mega_pathway_abundance.pl
###############################################################################
#
# DESCRIPTION: Parse blast output file in order to filter results on the best hit, % of alignment and % of similarity, evalue. Add the functional group associated
#
# INPUT:
#
# OUTPUT:
#
# USAGE: perl mega_pathway_abundance.pl -infile=  -correlation= -output=
#
#
# VERSION:
# - Author: Alban Mathieu (amathieu@enterome.com)
# - Date: 23/03.2015
# - Version 1
#
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


###############################################################################
### correlation ###
###############################################################################
open (FILE1b, $megapathway) or die "pbm pathway file: $usage";
while (<FILE1b>) {
    chomp;
    my @tab = split ("\t", $_);
    if ($_ =~ /^#[^#]/) {
        next;
    }
    elsif ($_ =~ /^##(.*)/) {
        $nom = $1;
    }
    else{
        $met{$tab[0]}{$nom} = 1;
    }
}

close FILE1b;

###############################################################################
#### Parse abundance table ###
###############################################################################
print localtime()."\t"."functional_abundance - Step 2/4\n";

my @samples;

open (FILE2, $a) or die "pbm FILE2 abun table: $usage";
while (<FILE2>) {
    if ($_ !~ /^#/) {
        chomp;
        my @tab = split ("\t", $_);
        if ($tab[0] eq "") {
            for my $i (1..$#tab){
                push (@samples, $tab[$i])
            }
        }
        else{
            $tab[0] =~/ko(\S+)/;
            my $pat = $1;
            if ($met{$pat}) {
                foreach my $k (keys %{$met{$pat}}){
                    for my $i (1..$#tab){
                        my $s = $samples[$i-1];
                        my $v = $tab[$i];
                        $met2{$k}{$s} += $v;
                    }
                    
                }
            }
        }
    }
}

close FILE2;

###############################################################################
### Writing ###
###############################################################################
print localtime()."\t"."functional_abundance - Step 3/4\n";
###############################################################################
open(W3, ">$output_meta") or die "pbm output_met: $usage";

print W3 "\t".join ("\t", @samples)."\n";

foreach my $m (keys %met2){
    my @valuesM;
    foreach my $s (@samples){
        if ($met2{$m}{$s}) {
            push (@valuesM, $met2{$m}{$s});
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
print localtime()."\t"."functional_abundance - Step 4/4\n";

print "Number of pathways = $tm\n";

