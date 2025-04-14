import pysam
import sys
import os

# Usage: python extract_fragments.py input.bam output.txt

if len(sys.argv) != 3:
    print("❌ Usage: python extract_fragments.py <input.bam> <output.txt>")
    sys.exit(1)

bam_file = sys.argv[1]
output_file = sys.argv[2]

bam = pysam.AlignmentFile(bam_file, "rb")
with open(output_file, "w") as out:
    for read in bam:
        if read.is_proper_pair and read.is_read1 and read.template_length > 0:
            if read.template_length < 1000:
                out.write(str(read.template_length) + "\n")
bam.close()

print(f"✅ Fragment lengths written to {output_file}")

