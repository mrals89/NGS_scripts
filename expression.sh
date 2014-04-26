#!/bin/bash
#PBS -N gene_express
#PBS -r n
#PBS -V
#PBS -l nodes=1:ppn=6
#PBS -l walltime=240:00:00
#PBS -d /home/mrals/ETP

#set -e

#General
PATH=$PATH:/home/mrals/pckges/Vienna/bin:/home/mrals/home/bin/:/home/mrals/bin/
#NGS
PATH=$PATH:/home/mrals/pckges/sratoolkit.2.3.4-2-centos_linux64/bin/:/usr/local/bowtie-0.12.7/:/usr/local/bowtie2-2.1.0/:/usr/local/bwa-0.7.4/:/usr/local/cufflinks-2.2.0/:/usr/local/FastQC/:/usr/local/samtools-0.1.18/:/usr/local/tophat-2.0.4/:/home/mrals/pckges/seqtk-master/

export PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
rvm use 2.0.0
#########################     1     ##########################
# First, environmental variables are defined, including the name of the executable that will be called, the number of processors for parallelization, the directory of the input files, the directory of output files, the reference annotation that will be used for expression quantification, the CDS file for CDS quantification, and others.

cuffdiff='/usr/local/cufflinks-2.2.0/cuffdiff'
CORES=6
INDIR=SAM_processed
LOGDIR=logs
CUFFQUANT=Cuffquant
#REFERENCE=reference/ref.gtf
REFERENCE=reference/CAC.gtf
MASK=reference/mask.gtf
export REFERENCE
REFFASTA=reference/CAC.txt
EXPRDIR=counts
BAM=`/usr/bin/ls $INDIR/*.3.bam`
NS30='Cuffquant/NS30A/abundances.cxb,Cuffquant/NS30B/abundances.cxb'
NS75='Cuffquant/NS75A/abundances.cxb,Cuffquant/NS75B/abundances.cxb'
NS270='Cuffquant/NS270A/abundances.cxb'
PICARD=/usr/local/picard-tools-1.67
TMPD=/home/mrals/ETP/tmp/

#########################     2     ##########################
# Next, the manually curated assembly is converted into refFlat format to be used to generate
# Additional RNAseq metrics with picard
#gtfToGenePred -genePredExt $CUFFLINKS/merged.gtf $CUFFLINKS/tmp.refflat
#awk 'BEGIN{FS="\t"};{print $12"\t"$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10}' $CUFFLINKS/tmp.refflat > $CUFFLINKS/merged.refflat
#REFFLAT=$CUFFLINKS/merged.refflat
#ANNOTATION=/home/mrals/ETP/$CUFFLINKS/merged.gtf
#export ANNOTATION
#for file in $FILES
#do
#	java -jar $PICARD/CollectRnaSeqMetrics.jar INPUT=$file REF_FLAT=$REFFLAT TMP_DIR=$TMPD STRAND_SPECIFICITY=FIRST_READ_TRANSCRIPTION_STRAND MINIMUM_LENGTH=50 CHART_OUTPUT=$LOGDIR/${file##*/*}.RNAseq_metrics.pdf OUTPUT=$LOGDIR/${file##*/*}.RNAseq_metrics.log REFERENCE_SEQUENCE=$REFFASTA ASSUME_SORTED=true
#done

#########################     3     ##########################
# Then, htseq-count is used to generate raw read counts for individual CDSs or for whole genes
# in the reference assembly.
parallel -j$CORES 'htseq-count -f bam -r pos -m intersection-nonempty -s yes {} $REFERENCE > counts/{/.}.counts' ::: $BAM


#########################     4     ##########################
# Next, genes are quantified in each expression set using cuffquant
for file in $BAM
do
    f=${file##*/};f=${f%*.*.*}
    #mkdir $CUFFQUANT/$f
    cuffquant -o $CUFFQUANT/$f -v -p $CORES -M $MASK -b $REFFASTA -u --library-type fr-firststrand $REFERENCE $file
done


#########################     5     ##########################
# Then, cuffdiff is performed for the factorial combinations of interest.
#/usr/local/cufflinks-2.2.0/cuffdiff -p $CORES -o $CUFFQUANT -T -b $REFFASTA -u -M $MASK --library-type fr-firststrand --library-norm-method geometric --min-reps-for-js-test 1 $REFERENCE $NS30 $NS75 $NS270

#########################     6     ##########################
# Next, gene expression levels are quantified using the reference transcriptome
cuffnorm -p $CORES -o $CUFFQUANT -L NS30,NS75,NS270 --library-type fr-firststrand --library-norm-method geometric $REFERENCE $NS30 $NS75 $NS270

## EOF-------------------------------------------
