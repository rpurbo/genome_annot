
use JSON;

#=======================================
# WF_sum_instrument.pl
#
# Script to extract Pacbio subreads data.
#
# ======================================

$def_loc = "smrt/results/filter_reports_filter_subread_stats.json";

if(! -f $def_loc){
	print "[FATAL] Could not find Pacbio subread report ...\n";
	exit;
}

print "[Assembly Subreads Info]\n";

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

print "Subread Count," . $data{"filter_subread.filter_subread_nreads"} . "\n";
print "Subread Total Bases," . $data{"filter_subread.filter_subread_nbases"} . "\n";
print "Subread Mean Length," . $data{"filter_subread.filter_subread_mean"} . "\n";
print "Subread N50 Length," . $data{"filter_subread.filter_subread_n50"} . "\n";


