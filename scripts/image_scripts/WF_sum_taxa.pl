

#=======================================
# WF_sum_assembly_taxa.pl
#
# Script to extract assembly data post filtering/trimming/circularization
#
# ======================================

$def_loc = "03_taxa_class/16S_rrna.rep.taxa.txt";
$fasta_loc = "02_rrna/16S_rrna.rep.fasta";
$aln_loc = "03_taxa_class/16S_rrna.rep.SILVA.txt";

if(! -f $def_loc || ! -f $fasta_loc || ! -f $aln_loc){
	print "[FATAL] Could not find complete rRNA files ...\n";
	exit;
}

print "[Taxonomy Class. Summary]\n";


#Read Alignment File
open (FILE, $aln_loc);
$buff1 = <FILE>;
$buff2 = <FILE>;
$dbinfo = <FILE>;
$dbinfo =~ m/Database:(.+)/;
$dbinfo = trim($1);
close(FILE);

#Read Taxa File
my %hits;
open (FILE, $def_loc);
$header = <FILE>;
while($buff = <FILE>){
	chomp $buff;
	@tok = split(/\t/,$buff);
	$id = trim($tok[0]);
	$hits{">".$id} = $buff;
}
close(FILE);


#Read rRNA Fasta File
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

$rrna_num = 0;
my %lens;
for $id (keys %seqs){
	$lens{$id} = length($seqs{$id});
	$rrna_num++;
}

if($rrna_num > 1){
	$MIX = "Multi";
}else{
	$MIX = "Single";
}


print "#rRNA Sequence(s)," . $rrna_num . "\n";
print "Isolate," . $MIX . "\n";
print "Database," . $dbinfo . "\n";
print "\n";

$st = 1;
for $id (keys %seqs){
	print "#==== rRNA [" . $st . "] ====\n";
	$seq = $seqs{$id};
	#print "Seq Name: " . $id . "\n";
	print "#Fields: query, subject, query len, aln%, ident%, e-value, bit-score\n";

	print $hits{$id} . "\n";

	print "\n";
	
	print $id . "\n";
	for($i=0;$i<length($seq);$i+=60){
		print substr($seq,$i,60) . "\n";
	}

	print "\n";
}



sub trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

