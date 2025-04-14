#!/bin/bash
# extract_fragments_all.sh

mkdir -p fragments

for bam in aligned_bams/*.bam; do
    sample=$(basename "$bam" .bam)
    echo "🐍 Processing $sample ..."
    python extract_fragments.py "$bam" "fragments/${sample}_fragments.txt"
done

