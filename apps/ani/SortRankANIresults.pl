#___________________________________________________________________________________________________
##author: Premkrishnan BV
##date: 17.04.2019
##usage: perl </scratch/prem/scripts_programs/ani/SortRankANIresults.pl>
##purpose: to sort the ANI.pl results based on ANI score and map ids to organism names
##__________________________________________________________________________________________________
##important: make sure you ran "CalculateANIScores.sh" successfully and "temp" folder is "not empty"
##__________________________________________________________________________________________________
#!usr/bin/perl
use strict;
use warnings;

my $library;
BEGIN { $library = $ARGV[0]; }

#point to libray
use lib "$library";
use ORG_MAP; #hash ids=>names

my $dir = $ARGV[1];

open FINAL,">ani_results.txt" or die "ani_results.txt $!\n";
opendir DIR,"$dir" or die "$dir $!\n";
while(my $file = readdir DIR)
{
        next if($file=~/^\.*$/);
        my $path = "$dir\/$file";
        opendir SUBDIR,"$path" or die "$path $!\n";
        while(my $subfile = readdir SUBDIR)
        {
                next if($subfile=~/^\.*$/);
                if($subfile=~/.*\.+out$/)
                {
                        my $filepath = "$dir\/$file\/$subfile";
                        open VAL,"<$filepath" or die "<$filepath> $!\n";
                        while(<VAL>)
                        {
                                print FINAL "$_\n";
                        }
                }
        }
}
closedir DIR;
close FINAL;

#rank and assign taxa names
system("sort -nrk3 ani_results.txt > temp_001.out");
#system("cut -f2-3 temp_001.out | cut -d / -f8 > temp_002.out");
system("cut -f2-3 temp_001.out | rev | cut -d / -f 1 | rev > temp_002.out");
system("rm temp_001.out");

open OUT,">FinalScoresANI.out" or die "Cannot open 'FinalScoresANI.out' file for writing!\n";
open ERR,">ERRORS.out" or die "Cannot open 'ERRORS.out' file for writing!\n";
print OUT "#ANI score\t#Organism\n";
open IN,"<temp_002.out" or die "Cannot open file temp_002.out!\n";
while(my $line = <IN>)
{
        chomp($line);
	next if($line=~/^\s*$/);
        my ($id,$ani_value) = split("\t",$line);
        $id=~s/_genomic\.fna//gi;
        #my $organism = ($assembly_organism_map{$id}) ? $assembly_organism_map{$id} : 'NA';
	if(defined($assembly_organism_map{$id})) 
	{
		my $organism = $assembly_organism_map{$id};
		print OUT "$ani_value\t$organism\n";
	}
	else
	{
		print ERR "$line\n";
	        #print "$ani_value\t--\n";
	}
}
close IN;
close OUT;
close ERR;
system("rm temp_002.out");
#end
