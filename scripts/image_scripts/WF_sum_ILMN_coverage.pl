#=======================================
## WF_sum_ILMN_coverage.pl
##
## Script to get Illumina pilon coverage
##
## ======================================



$read1 = $ARGV[0]; # Input from 00_polish/pilonPhysicalCoverage.wig

$current = "";
my %covs;
my %lens;

open (FILE, $read1);
$header = <FILE>;
while($buff = <FILE>){
	chomp $buff;
	if($buff =~ m/fixedStep chrom=(.+) start/){
		$chrom = $1;
		$current = $chrom;
	}else{
		$cov = $buff;
		$lens{$current}++;
		$covs{$current} += $cov;
	}
}
close (FILE);


print "[ILMN Coverage Info - top 25]\n";
print "#Field: Contig Name, Contig Len, Avg. Coverage\n";

my $total = 0;
my $cnt = 0;
my $totallen = 0;
my %db;
for $chrom (keys %covs){
	$cov = sprintf("%.2f", $covs{$chrom} / $lens{$chrom} );
	$db{$chrom} = $cov;
	$total += $cov;
	$totallen += $lens{$chrom};
	$cnt++;
}

$i=0;
for $chrom (sort {$lens{$b} <=> $lens{$a}} keys %lens){
	print $chrom . "\t" . $lens{$chrom} . "\t" . $db{$chrom} . "\n";
	$i++;
	if($i >25){
		last;
	}
}

print "Average\t" . sprintf("%.2f", $totallen / $cnt) . "\t" . sprintf("%.2f", $total / $cnt) . "\n";


sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
