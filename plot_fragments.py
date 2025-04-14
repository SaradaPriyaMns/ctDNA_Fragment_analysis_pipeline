import os
import matplotlib.pyplot as plt
import seaborn as sns

sns.set(style="whitegrid")

input_dir = "fragments_90_150"
output_dir = "plots"
os.makedirs(output_dir, exist_ok=True)

for file in os.listdir(input_dir):
    if file.endswith(".txt"):
        sample = file.replace("_90_150.txt", "")
        file_path = os.path.join(input_dir, file)

        # Skip empty files
        if os.stat(file_path).st_size == 0:
            print(f"Skipping empty file: {file}")
            continue

        with open(file_path) as f:
            lengths = [int(line.strip()) for line in f if line.strip().isdigit()]

        if not lengths:
            print(f"No valid data in: {file}")
            continue

        plt.figure(figsize=(8, 5))
        sns.histplot(lengths, bins=30, kde=True)
        plt.title(f"Fragment Size Distribution: {sample}")
        plt.xlabel("Fragment Size (bp)")
        plt.ylabel("Frequency")
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, f"{sample}_90_150_distribution.png"))
        plt.close()
        print(f"Plot saved: {sample}_90_150_distribution.png")

