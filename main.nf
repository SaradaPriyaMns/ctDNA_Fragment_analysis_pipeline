#!/usr/bin/env nextflow

params.reads = "fastq_data/*_1.fastq.gz"
params.ref = "reference_grch38/GRCh38.fa"
params.sif = "gatk_4.1.4.0.sif"

Channel
    .fromFilePairs(params.reads, flat: true)
    .set { read_pairs }

process ALIGN {
    tag "$sample_id"
    publishDir "aligned_bams", mode: 'copy'

    input:
    set sample_id, file(reads) from read_pairs

    output:
    file("${sample_id}.bam")

    script:
    """
    bwa mem -t 4 $params.ref ${reads[0]} ${reads[1]} | \
      samtools sort -@ 2 -o ${sample_id}.bam
    samtools index ${sample_id}.bam
    """
}

process EXTRACT_FRAGMENTS {
    tag "$bam_file"
    publishDir "fragments_90_150", mode: 'copy'

    input:
    file bam_file from ALIGN.out

    output:
    file "*.txt"

    script:
    def sample = bam_file.simpleName
    """
    python extract_fragments.py $bam_file fragments/${sample}_fragments.txt
    awk '\$1 >= 90 && \$1 <= 150' fragments/${sample}_fragments.txt > ${sample}_90_150.txt
    """
}

process MUTECT2 {
    tag "$bam_file"
    publishDir "variants", mode: 'copy'

    input:
    file bam_file from ALIGN.out

    output:
    file "*.unfiltered.vcf"

    script:
    def sample = bam_file.simpleName
    """
    singularity exec $params.sif gatk Mutect2 \
      -R $params.ref \
      -I $bam_file \
      -tumor $sample \
      -O ${sample}.unfiltered.vcf
    """
}

process FILTER_VARIANTS {
    tag "$vcf_file"
    publishDir "variants_filtered", mode: 'copy'

    input:
    file vcf_file from MUTECT2.out

    output:
    file "*.filtered.vcf"

    script:
    def sample = vcf_file.simpleName.replace('.unfiltered','')
    """
    singularity exec $params.sif gatk FilterMutectCalls \
      -V $vcf_file \
      -R $params.ref \
      -O ${sample}.filtered.vcf
    """
}

process SUMMARIZE {
    publishDir "variant_summaries", mode: 'copy'

    input:
    file vcf_files from FILTER_VARIANTS.out.collect()

    output:
    file("variant_summary.tsv")
    file("variant_summary.csv")

    script:
    """
    echo -e "Sample\\tNumVariants" > variant_summary.tsv
    echo "Sample,NumVariants" > variant_summary.csv
    for vcf in *.filtered.vcf; do
        sample=\$(basename \$vcf .filtered.vcf)
        count=\$(grep -v "^#" \$vcf | wc -l)
        echo -e "\$sample\\t\$count" >> variant_summary.tsv
        echo "\$sample,\$count" >> variant_summary.csv
    done
    """
}

