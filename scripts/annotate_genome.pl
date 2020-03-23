#!/cm/shared/apps/devel/perl/5.30.0/bin/perl

use REST::Client;
use MIME::Base64;
use JSON;
use Data::Dumper;
use Cwd;
use Text::Template;
use File::Basename;

$scriptdir = dirname(Cwd::abs_path(__FILE__)) ; 

#=============================== Annotation Workflow Template Config =======================================

$FUNGI_WF=$scriptdir ."/../workflow/fungi_nonpbio.v02.snk";
$BACTERIA_WF=$scriptdir . "/../workflow/bacteria_nonpbio.v02.snk";
$PBS_TEMPLATE=$scriptdir . "/../conf/template.pbs";
$SIMG_BASEDIR=$scriptdir . "/../simg";
$APP_BASEDIR=$scriptdir . "/../apps";

$THREADS=16;
$QUEUE="std";

#============================================================================================================


if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '' )
{
	help();
	exit;
}

# Read manifest file

my %assemblies;
my %types;
my %paths;
$manifest = $ARGV[0];
open(FILE,$manifest) or die "Can't open manifest file: ". $manifest ."\n";;
while($buff=<FILE>){
	chomp $buff;
	@tok=split(/\t/,$buff);
	$name = $tok[0];	
	$path = $tok[1];
	$type = $tok[2];
	if($type !~ m/bacteria|fungi/){
		print "Unknown annotation type: ". $type . "\n";
		exit;
	}
	$assemblies{$name} = 1;
	$paths{$name} = $path;
	$types{$name} = $type;

        if (-e $path){
                print "[INFO] found ". $name . " with file: " . $path. "\n";
        }else{
                print "[FATAL] file: " . $path. " can't be found!\n";
		exit;
        }

	#check if fasta file
	$cmd = "head -n 1 ". $path ." | cut -c 1 ";
	$ret = `$cmd`;
	$retval = $?;

        if ($retval == 0){
                print "[INFO] fasta check done ... ".$path." \n";
        }else{
                print "[FATAL] doesn't look like a fasta file ... " . $path . "\n";
                exit;
        }

}		
close(FILE);


$basedir = getcwd;

for $name ( keys %assemblies ) {
	$path = $paths{$name};		

	if (-e $path){
		print "[INFO] found ". $name . " with file: " . $path. "\n";
	}else{
		print "[FATAL] file: " . $path. " can't be found!\n";
		exit;
	}	
	
	$workdir = $basedir . "/" . $name;
	
	print "[INFO] creating directory: " . $workdir . "\n";
	$cmd = "mkdir -p " . $workdir;
	$ret = `$cmd`;
	$retval = $?;
	if ($retval == 0){
		print "[INFO] done ... \n";
	}else{
		print "[INFO] failed creating ... " . $workdir . "\n";
		exit;
	}

	print "[INFO] copying assembly data to " . $workdir . "\n";
	$cmd = "cp " . $path . " " . $workdir . "/contigs.fasta";
	$ret = `$cmd`;
	$retval = $?;
	if ($retval == 0){
        	print "[INFO] done ... \n";
	}else{
		print "[FATAL] failed copying assembly file ... " . $workdir . "\n";
		exit;
	}
		
	# Generate submission file
	print "[INFO] generating submission file " . $workdir . "/job.pbs\n";		

	if(lc($types{$name}) eq "bacteria"){
		$select_wf = $BACTERIA_WF;
	}elsif(lc($types{$name}) eq "fungi"){
		$select_wf = $FUNGI_WF;
	}else{
		print "[FATAL] Unrecognized genome type: " . $types{$name} . "\n";
		exit;
	}

	my $template = Text::Template->new(SOURCE => $PBS_TEMPLATE) or die "[FATAL] could not access template file\n";
	my %vars = (
		asm_name => $name,
		queue_name => $QUEUE,
		threads => $THREADS,
		log_name => $workdir . "/pbs.log",
		workdir => $workdir,
		workflow => $select_wf,
		simg => $SIMG_BASEDIR,
		apps => $APP_BASEDIR
	);

	my $jobscript = $template->fill_in(HASH => \%vars);
	open(OUT,">" . $workdir ."/job.pbs") or die "[FATAL] could not generate pbs submission script\n";
	print OUT $jobscript;
	close(OUT);

	# Copy workflow to local dir
	$cmd = "cp " . $select_wf . " " . $workdir . "/workflow.snk";
	$ret = `$cmd`;


	# Submit annotation job	
	print "[INFO] submitting jobs to PBS\n";
	$cmd = "qsub " . $workdir ."/job.pbs";
	$ret = `$cmd`;
	$retval = $?;
               
	if ($retval == 0){
		print "[INFO] done ... " . $ret . "\n";
	}else{
		print "[INFO] failed submitting job ... \n";
		exit;
	}
		
	print "=========================\n";
}





sub help { 
	print "Usage: \n";
	print "./annotate_genome_pacbio.pl <manifest-file>\n";
	print "\n";
	print "  manifest-file is a tab-delimited text file with\n";
	print "  the following format: \n\n";
	print "  <assembly_name>\t<assembly_fasta_file_path>\t<bacteria|fungi>\n";
	print "  <assembly_name>\t<assembly_fasta_file_path>\t<bacteria|fungi>\n";
	print "  ...\n\n";
}




