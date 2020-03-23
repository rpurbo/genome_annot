
use JSON;

#=======================================
# WF_split_contigs.pl
#
# Split individual contig to one file
#
# ======================================

$fasta_loc = "01_circularize/polished_assembly.clean.circular.fasta";
$target_dir = "01_circularize/contigs";

if(! -f $fasta_loc){
	print "[FATAL] Could not find Pacbio assembly files ...\n";
	exit;
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


for $id (keys %seqs){
	$seq = $seqs{$id};
	$id =~ m/>(.+?)(\s|$)/g;
	$shortid = $1;

	$target = $target_dir . "/" . $shortid . ".fasta";
	open(OUT,">".$target);
	print OUT $id . "\n";	
        for($i=0;$i<length($seq);$i+=60){
                print OUT substr($seq,$i,60) . "\n";
        }
	close(OUT);

}


sub trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

