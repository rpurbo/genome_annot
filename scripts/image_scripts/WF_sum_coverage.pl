
use JSON;

#=======================================
# WF_sum_coverage.pl
#
# Script to extract HGAP3 coverage & quality data.
#
# ======================================

$def_loc = "smrt/results/corrections.json";

if(! -f $def_loc){
	print "[FATAL] Could not find Pacbio assembly report ...\n";
	exit;
}

print "[Assembly HGAP3 Coverage Info]\n";

my $json_str;
my %data;

open(FILE,$def_loc);
while (<FILE>) { $json_str .= $_ };
close(FILE);

my $decoded = decode_json($json_str);
my @items = @{$decoded->{'attributes'}};
foreach my $item ( @items ) {
	$id = $item->{"id"} ;
	$val = $item->{"value"} ;	
	$data{$id} = $val;
}

$avg_len = $data{"variants.mean_contig_length"};
$avg_accuracy = $data{"variants.weighted_mean_concordance"};
$avg_cov = $data{"variants.weighted_mean_coverage"};

my %tables;
my %headers;
my @items = @{$decoded->{'tables'}->[0]->{'columns'}};
foreach my $item ( @items ) {
	$header = $item->{"header"};
	$headers{$header} = 1;
	my @vals = @{$item->{"values"}};

	for($i=0;$i<scalar(@vals);$i++){
		$tables{$i}{$header} = $vals[$i];
	}
}

print "#Field: Contig Name, Contig Len, Accuracy, Base Coverage\n";
for $i (sort keys %tables){
	print $tables{$i}{"Reference"} . "\t";
	print $tables{$i}{"Reference Length"} . "\t";
	print $tables{$i}{"Consensus Accuracy"} . "\t";
	print $tables{$i}{"Base Coverage"} . "\n";

}

print "Average\t". $avg_len . "\t" . $avg_accuracy . "\t" . $avg_cov . "\n"; 




