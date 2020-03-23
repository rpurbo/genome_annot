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

$FUNGI_WF=$scriptdir . "/../workflow/fungi_plat.v03.snk";
$BACTERIA_WF=$scriptdir . "/../workflow/bacteria_plat.v03.snk";
$PBS_TEMPLATE=$scriptdir . "/../conf/template.pbs";
$SIMG_BASEDIR=$scriptdir . "/../simg";
$APP_BASEDIR=$scriptdir . "/../apps";

$THREADS=16;
$QUEUE="std";

#============================================================================================================


#================================ SMRT Portal Connection Config =============================================

$setpoint = "http://169.254.100.24:8080";
$url = "/smrtportal/api/jobs/by-protocol/RS_HGAP_Assembly.3";
$userpass = "api_user:strange-server-access-CAPITAL99";
$options = "options={\"page\":1,\"rows\":2000,\"sortOrder\":\"desc\",\"sortBy\":\"jobId\"}&jobStatus=Completed";

$smrt_shares_prefix="/seq01/mach/pacbio_1/userdata/jobs";

#============================================================================================================


if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '' )
{
	help();
	exit;
}

# Read manifest file
#Format:	<name>\t<ilmn_R1>\t<ilmn_R2>\t<type>
my %assemblies;
my %types;
my %reads1;
my %reads2;

$manifest = $ARGV[0];
open(FILE,$manifest) or die "Can't open manifest file: ". $manifest ."\n";;
while($buff=<FILE>){
	chomp $buff;
	@tok=split(/\t/,$buff);
	$name = $tok[0];
	$read1 = $tok[1];
	$read2 = $tok[2];
	$type = $tok[3];
	$type =~ s/^\s+|\s+$//g;

	if (-e $read1 && -e $read2){
		print "[INFO] found ". $name . " with file: " . $read1. "\n";
		print "[INFO] found ". $name . " with file: " . $read2. "\n";
	}else{
		print "[FATAL] files can't be found!\n";
		exit;
	}

	if($type !~ m/bacteria|fungi/g){
		print "Unknown annotation type: ". $type . "\n";
		exit;
	}
	$assemblies{$name} = 1;
	$types{$name} = $type;
	$reads1{$name} = $read1;
	$reads2{$name} = $read2;
}	
close(FILE);


# Connect to SMRTportal and copy the assemblies' data.

my $client = REST::Client->new();
$client->setHost($setpoint);
$client->addHeader( "Authorization", "Basic ".encode_base64($userpass));
$client->POST( $url , $options);
die $client->responseContent() if( $client->responseCode() >= 300 );
my $r = decode_json( $client->responseContent() );

$basedir = getcwd;
my @rows = @{$r->{"rows"} };
foreach $row ( @rows ) {
	$name = $row->{'name'};
	if($assemblies{$name} == 1){
		$pre = substr($row->{'jobId'},0,2);
		$id = $row->{'jobId'};

		print "[INFO] found ". $name . " with job ID " . $id. "\n";
		
		$workdir = $basedir . "/" . $name;
		$smrtdir = $workdir . "/smrt";
	
		print "[INFO] creating directory: " . $workdir . "\n";
		$cmd = "mkdir -p " . $smrtdir;
		$ret = `$cmd`;
		$retval = $?;
		if ($retval == 0){
			print "[INFO] done ... \n";
		}else{
			print "[INFO] failed creating ... " . $workdir . "\n";
			exit;
		}

		print "[INFO] copying assembly data to " . $smrtdir . "\n";
		$cmd = "cp " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/input.fofn " . $smrtdir . "/ &&";
		$cmd .= " cp " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/settings.xml " . $smrtdir . "/ &&";
		$cmd .= " cp -r " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/movie_metadata " . $smrtdir . "/ &&";
		$cmd .= " cp " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/data/coverage.bed " . $smrtdir . "/ &&";
		$cmd .= " cp " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/data/polished_assembly.fasta.gz " . $smrtdir . "/ &&";
		$cmd .= " cp " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/data/polished_assembly.fastq.gz " . $smrtdir . "/ &&";
		$cmd .= " cp -r " . $smrt_shares_prefix . "/0".$pre."/0" . $row->{'jobId'} . "/results " . $smrtdir . "/ &&";
		$cmd .= " gzip -d " . $smrtdir . "/polished_assembly.fasta.gz && gzip -d " . $smrtdir . "/polished_assembly.fastq.gz";

		$ret = `$cmd`;
		$retval = $?;
                if ($retval == 0){
                        print "[INFO] done ... \n";
                }else{
                        print "[INFO] failed copying smrtportal data ... " . $workdir . "\n";
                        exit;
                }
	
		# Copying Illumina data
		$cmd = " cp " . $reads1{$name} . " " . $workdir . "/ilmn.R1.fastq &&";
		$cmd .= " cp " . $reads2{$name} . " " . $workdir . "/ilmn.R2.fastq ";
		$ret = `$cmd`;	
		$retval = $?;
		if ($retval == 0){
			print "[INFO] copying ILMN data done ... \n";
		}else{
			print "[FATAL] failed copying ILMN data ... " . $workdir . "\n";
			exit;
		}
		

		# Generate submission file
		print "[INFO] generating submission file " . $smrtdir . "/job.pbs\n";		

		if(lc($types{$name}) eq "bacteria"){
			$select_wf = $BACTERIA_WF
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
}





sub help { 
	print "Usage: \n";
	print "./annotate_genome_pacbio_plat.pl <manifest-file>\n";
	print "\n";
	print "  manifest-file is a tab-delimited text file with\n";
	print "  the following format: \n\n";
	print "  <hgap_assembly_name>\t<fastq1_path>\t<fastq2_path>\t<bacteria|fungi>\n";
	print "  <hgap_assembly_name>\t<fastq1_path>\t<fastq2_path>\t<bacteria|fungi>\n";
	print "  ...\n\n";
}




