#!/bin/bash
#SBATCH --job-name=cfDNA_fragments
#SBATCH --output=logs/frag_pipeline_%j.out
#SBATCH --error=logs/frag_pipeline_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH --mail-user=your_email@domain.com
#SBATCH --mail-type=END,FAIL

module load python/3.8.1
source /scratch/n.mandala/lid_biop/cfDNA_env_fixed/bin/activate

mkdir -p fragments fragments_90_150 plots

shopt -s nullglob
bam_files=(aligned_bams/*.bam)

if [ ${#bam_files[@]} -eq 0 ]; then
  echo "No BAM files found in aligned_bams/. Exiting."
  exit 1
fi

if [ ! -f extract_fragments.py ]; then
  echo "Missing extract_fragments.py script!"
  exit 1
fi

for bam in "${bam_files[@]}"; do
  sample=$(basename "$bam" .bam)
  frag_out="fragments/${sample}_fragments.txt"
  filtered_out="fragments_90_150/${sample}_90_150.txt"

  echo "Extracting fragment sizes for $sample"
  python extract_fragments.py "$bam" "$frag_out"

  echo "Filtering 90-150 bp"
  awk '$1 >= 90 && $1 <= 150' "$frag_out" > "$filtered_out"
done

echo "Fragment pipeline done."

