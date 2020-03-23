
use JSON;

#=======================================
# WF_sum_assembly.pl
#
# Script to extract HGAP3 assembly data.
#
# ======================================

$def_loc = "smrt/results/polished_report.json";

if(! -f $def_loc){
	print "[FATAL] Could not find Pacbio assembly report ...\n";
	exit;
}

print "[Assembly Pre-QC Stats]\n";

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

print "Contig Count," . $data{"polished_assembly.polished_contigs"} . "\n";
print "Contig Total Bases," . $data{"polished_assembly.sum_contig_lengths"} . "\n";
print "Contig N50 Length," . $data{"polished_assembly.n_50_contig_length"} . "\n";
print "Contig Max Length," . $data{"polished_assembly.max_contig_length"} . "\n";


