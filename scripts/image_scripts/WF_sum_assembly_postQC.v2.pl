
use JSON;

#=======================================
# WF_sum_assembly_postQC.pl
#
# Script to extract assembly data post filtering/trimming/circularization
#
# ======================================

$def_loc = "smrt/results/corrections.json";
$fasta_loc = "01_circularize/polished_assembly.clean.circular.fasta";
$cov_loc = "smrt/coverage.bed";

if(! -f $cov_loc || ! -f $fasta_loc){
	print "[FATAL] Could not find Pacbio assembly files ...\n";
	exit;
}

print "[Assembly Post-Circ. Stats]\n";


#Extract Coverage Data

my %data;
my %tables;
my %headers;
my %raw_covs;
my $lens;

open (FILE, $cov_loc);
$buff=<FILE>;
while($buff = <FILE>){
	chomp $buff;
	@tok=split(/\t/,$buff);
	$name = $tok[0];
	$st = $tok[1];
	$ed = $tok[2];
	$cov = $tok[4];
	$len = abs($ed-$st);	


	$lens{$name} += $len;
	$rawcov = $cov * $len;
	$raw_covs{$name} += $rawcov;

}
close(FILE);

my %coverages;
for $name (keys %lens){
	$len = $lens{$name};
	$raw = $raw_covs{$name};
	$meancov = $raw / $len;
	$coverages{$name} = $meancov;
}


#Read Fasta File

my %seqs;

$current_header = "";
$current_reads = "";

open (FILE, $fasta_loc);
while($buff = <FILE>){
	chomp $buff;
        if(substr($buff,0,1) eq ">"){
		if($current_reads ne ""){
			$seqs{$current_header} = $current_reads;
		}
                $current_header = $buff;
                $current_reads = "";

        }else{
                $current_reads .= trim($buff);
        }
}
close (FILE);

$seqs{$current_header} = $current_reads;


#Extract Overall Stats
$totallen = 0;
$maxlen = 0;
$n50len = 0;
$GC_all = 0;
$ctg_count = 0;
my %len_arr;
my %gc_arr;
my %circ_arr;

for $id (keys %seqs){
	$seq = $seqs{$id};
	$len = length($seq);
	$len_arr{$id} = $len;

	if($len > $maxlen){
		$maxlen = $len;
	}

	
	$GC = $seq =~ tr/C|G|c|g//;
	$gc_arr{$id} = $GC;
	$GC_all += $GC;		

	$totallen += $len;
	$ctg_count++;

	#$id =~ m/circular=(.+?)\s/;
	#$circ = $1;
	#$circ_arr{$id} = $circ;

	if($id =~ m/circular=true/){
		$circ_arr{$id} = "true";
	}else{
		$circ_arr{$id} = "false";
	}

}	

$GC_overall = sprintf("%.2f",$GC_all / $totallen);

$uptolen = 0;
for $id (sort {$len_arr{$b} <=> $len_arr{$a}}keys %len_arr){
	#print $id . "\t" . $len_arr{$id} . "\n";
	$currlen = $len_arr{$id};
	$uptolen += $currlen;

	if($uptolen > (0.5 * $totallen)){
		$n50len = $currlen;
		last;
	}
}

print "Contig Count," . $ctg_count . "\n";
print "Contig Total Bases," . $totallen . "\n";
print "Contig N50 Length," . $n50len . "\n";
print "Contig Max Length," . $maxlen . "\n";
print "Contig GC Content," . $GC_overall . "\n";
print "\n";

print "#Field: Contig, Length, Coverage, GC, Circular\n";
for $id (sort keys %len_arr){
	$len = $len_arr{$id};
	$gc = $gc_arr{$id};
	$gcperc = sprintf("%.2f",$gc / $len);
	$circ = $circ_arr{$id};

	$shortid = "";
	$id =~ m/>(.+?)(\s|$)/g;
	$shortid = $1;

	$cov = sprintf("%.2f",$coverages{$shortid});	

	print $shortid . "\t" . $len . "\t" . $cov . "\t" . $gcperc . "\t" . $circ . "\n";
}


sub trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

