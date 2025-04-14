#!/bin/bash
#SBATCH --job-name=cfDNA_mutect2_pipeline
#SBATCH --output=logs/mutect2_pipeline_%j.out
#SBATCH --error=logs/mutect2_pipeline_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

# Load necessary modules
module load samtools
module load singularity

# Set paths
REF="reference_grch38/GRCh38.fa"
SIF="gatk_4.1.4.0.sif"

# Create directories if not present
mkdir -p fixed_bams variants logs

# Step 1: Add Read Groups and Index BAMs
echo "Adding read groups and indexing..."
for bam in aligned_bams/*.bam; do
    sample=$(basename "$bam" .bam)
    out_bam="fixed_bams/${sample}_rg.bam"

    samtools addreplacerg -r "@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA" \
        -o "$out_bam" "$bam"

    samtools index "$out_bam"
done

# Step 2: Run GATK Mutect2 for all BAMs
echo "Running GATK Mutect2..."
for bam in fixed_bams/*_rg.bam; do
    sample=$(basename "$bam" _rg.bam)
    vcf_out="variants/${sample}.unfiltered.vcf"

    singularity exec "$SIF" gatk Mutect2 \
        -R "$REF" \
        -I "$bam" \
        -tumor "$sample" \
        -O "$vcf_out"
done

echo "Pipeline completed successfully."

