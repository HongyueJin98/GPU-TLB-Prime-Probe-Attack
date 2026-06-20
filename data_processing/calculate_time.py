import re
import numpy as np
from scipy.stats import gmean

# File path
FILE_PATH = "time_mapping/time_8.txt"
OUTPUT_PATH = "8_processed.txt"


def parse_file(file_path):
    """ Parses the file and extracts time mapping data. """
    data = {}
    
    with open(file_path, 'r') as file:
        content = file.read()
        first_delta_index = content.find("delta:")
        if first_delta_index == -1:
            return data
        
        content = content[first_delta_index:]
        groups = content.strip().split("\n\n")
        
        for group in groups:
            lines = group.strip().split("\n")
            if not lines:
                continue

            delta_match = re.match(r"delta:\s*(\d+)", lines[0])
            if not delta_match:
                continue
            
            numbers = [int(num) for line in lines[1:] for num in line.split()]
            
            for set_number, time_value in enumerate(numbers):
                set_number = str(set_number)
                data.setdefault(set_number, []).append(time_value)
    
    return data


def calculate_statistics(data, output_path):
    """ Computes statistics and writes them to a file. """
    with open(output_path, 'w') as output_file:
        for set_number, times in data.items():
            filtered_times = [t for t in times if t <= 50000]
            
            if filtered_times:
                geo_mean = gmean(filtered_times)
                arith_mean = np.mean(filtered_times)
                median = np.median(filtered_times)
                variance = np.var(filtered_times)
                output_file.write(f"SET {set_number}: Geometric Mean = {geo_mean:.2f}, "
                                  f"Median = {median:.2f}, "
                                  f"Arithmetic Mean = {arith_mean:.2f}, "
                                  f"Variance = {variance:.2f}\n")
            else:
                output_file.write(f"SET {set_number}: No valid times below threshold.\n")
    
    print(f"Statistics saved to {output_path}")


# Process file and compute statistics
data = parse_file(FILE_PATH)
calculate_statistics(data, OUTPUT_PATH)

