#!/bin/bash
#SBATCH --job-name=cfDNA_align
#SBATCH --output=logs/align_%j.out
#SBATCH --error=logs/align_%j.err
#SBATCH --time=8:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL       # Send email on job END and FAIL
#SBATCH --mail-user=n.mandala@northeastern.edu

module load bwa/0.7.17
module load bowtie/2.5.2
module load samtools/1.9

FASTQ_DIR="fastq_data"
REF="reference_grch38/GRCh38.fa"
OUT_DIR="aligned_bams"

mkdir -p $OUT_DIR logs

for R1 in $FASTQ_DIR/*_1.fastq.gz; do
  SAMPLE=$(basename $R1 _1.fastq.gz)
  R2="$FASTQ_DIR/${SAMPLE}_2.fastq.gz"

  echo "Aligning $SAMPLE ..."
  bwa mem -t 8 $REF $R1 $R2 | \
    samtools sort -@ 4 -o $OUT_DIR/${SAMPLE}.bam

  samtools index $OUT_DIR/${SAMPLE}.bam
  echo "Done: $SAMPLE"
done

