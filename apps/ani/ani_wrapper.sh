#!/bin/sh

module load parallel
module load perl


usage()
{
	echo "usage: ani_wrapper.sh -t <num_threads> -i <input_fasta> -l <ref_genomes_list> -m <ref_genomes_mapping_file> -o <output_directory>"
}

BASEDIR=$(dirname "$0")
bl=$BASEDIR"/blastall"
fd=$BASEDIR"/formatdb"
ani_script=$BASEDIR"/ANI.pl"
sorter=$BASEDIR"/SortRankANIresults.pl"

while [ "$1" != "" ]; do
	case $1 in
	-t  )	shift
		threads=$1
		;;
	-i  ) 	shift
		input=$1
		;;
	-l  )	shift
		list=$1
		;;
	-m  )	shift
		map=$1
		mapdir=$(dirname "$map")
		;;
	-o  )	shift
		outdir=$1
		;;
        * )	usage
		exit 1
    esac
    shift
done

if [ ! -f "$bl" ]
then
        echo "[FAIL] $bl not found."
        exit 1
fi

if [ ! -f "$fd" ]
then
        echo "$[FAIL] fd not found."
        exit 1
fi

if [ ! -f "$input" ]
then
        echo "[FAIL] $input not found."
        exit 1
fi

if [ ! -f "$list" ]
then
        echo "[FAIL] $list not found."
        exit 1
fi

if [ ! -f "$map" ]
then
        echo "[FAIL] $map not found."
        exit 1
fi

if [ ! -f "$ani_script" ]
then
        echo "[FAIL] $ani_script not found."
        exit 1
fi

if [ ! -f "$sorter" ]
then
        echo "[FAIL] $sorter not found."
        exit 1
fi

#Create output dir
echo "[STATUS] creating $outdir..."
mkdir -p $outdir
if [ ! -d "$outdir" ]
then
        echo "[FAIL] $outdir cannot be created."
        exit 1
fi


# Run ANI.pl in parallel
echo "[STATUS] running ANI script on $threads threads ..."
cat $list | awk -v as=$ani_script -v inp=$input -v out=$outdir -v bl=$bl -v fd=$fd -F"/" \
'{printf "perl "as" -bl "bl" -fd "fd" -qr "inp" -sb "$0" -od "out"/"$NF"\n"}' | parallel --jobs $threads

echo "[STATUS] completed ANI scripts ..."

# Run Rank Sorter
echo "[STATUS] running ANI rank sorter ..."
perl $sorter $mapdir $outdir
echo "[STATUS] completed ANI rank sorter, result is written to FinalScoresANI.out"




