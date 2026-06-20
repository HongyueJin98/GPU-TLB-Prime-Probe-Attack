import os
import pandas as pd
import pprint
import numpy

def process_files_in_directory(input_dir, output_geo_file, output_arith_file, output_med_file):
    """
    Processes all files in the directory, extracting geometric mean, median, and arithmetic mean.
    """
    geometric_means = {}
    medians = {}
    arithmetic_means = {}

    for filename in sorted(os.listdir(input_dir)):
        if filename.endswith("_processed.txt"):
            file_index = int(filename.split("_")[0])
            file_path = os.path.join(input_dir, filename)

            with open(file_path, 'r') as f:
                geo_row = {}
                median_row = {}
                arith_row = {}

                for line in f:
                    line = line.strip()
                    if line.startswith("SET"):
                        parts = line.split(":")
                        set_number = parts[0].split(" ")[1]
                        metrics = parts[1].split(",")
                        geometric_mean = float(metrics[0].split("=")[1].strip())
                        median = float(metrics[1].split("=")[1].strip())
                        arithmetic_mean = float(metrics[2].split("=")[1].strip())

                        geo_row[set_number] = geometric_mean
                        median_row[set_number] = median
                        arith_row[set_number] = arithmetic_mean

                geometric_means[file_index] = geo_row
                medians[file_index] = median_row
                arithmetic_means[file_index] = arith_row

    
    geo_df = pd.DataFrame.from_dict(geometric_means, orient='index')
    med_df = pd.DataFrame.from_dict(medians, orient='index')
    arith_df = pd.DataFrame.from_dict(arithmetic_means, orient='index')

    
    geo_df.to_csv(output_geo_file)
    med_df.to_csv(output_med_file)
    arith_df.to_csv(output_arith_file)

    print(f"Geometric means saved to: {output_geo_file}")
    print(f"Arithmetic means saved to: {output_arith_file}")
    print(f"Medians saved to: {output_med_file}")

# Define file paths
input_directory = "/home/hjin/all_code/useful/process_data" 
output_geometric_csv = "geometric_means.csv"
output_arithmetic_csv = "arithmetic_means.csv"
output_median_csv = "medians.csv"


process_files_in_directory(input_directory, output_geometric_csv, output_arithmetic_csv, output_median_csv)

