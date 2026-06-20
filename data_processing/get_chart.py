import pandas as pd
import matplotlib.pyplot as plt

# File paths for input data
time_file_path = "medians.csv"  # CSV file containing time data
evicted_file_path = "generated_data.csv"  # CSV file containing evicted data

# Load data from CSV files
time_data = pd.read_csv(time_file_path, index_col=0)
evicted_data = pd.read_csv(evicted_file_path, index_col=0)

# Fill NaN values with -1 in evicted data
evicted_data = evicted_data.fillna(-1)

# Create a mapping of evicted numbers to time values
new_data = {}
for set_number in evicted_data.columns:
    evicted_numbers = evicted_data[set_number].astype(int)
    time_values = time_data[set_number]
    new_data[set_number] = dict(zip(evicted_numbers, time_values))

# Extract all unique evicted numbers and create a new DataFrame
all_evicted_nums = sorted(set(num for column in new_data.values() for num in column.keys()))
new_table = pd.DataFrame(index=all_evicted_nums, columns=new_data.keys())

# Populate the new DataFrame with time values
for set_number, mapping in new_data.items():
    for evicted_num, time_value in mapping.items():
        new_table.at[evicted_num, set_number] = time_value

# Save the processed data to a new CSV file
new_table.to_csv("mapping_table.csv", index_label="Evicted Num")
print("Data saved to mapping_table.csv")

# Load the processed data
data = pd.read_csv("mapping_table.csv", index_col=0)

# Filter data for specific columns and rows
filtered_data = data.loc[0:8, data.columns[192:256]]

# Generate a segmented line plot
plt.figure(figsize=(15, 10))

for column in filtered_data.columns:
    valid_data = filtered_data[column].dropna()  # Remove NaN values
    plt.plot(valid_data.index, valid_data.values, label=column, marker='o', linestyle='-')

# Configure plot labels and legend
plt.xlabel("Evicted Num")
plt.ylabel("Time")
plt.legend(title="Set", loc='upper left')
plt.grid(True)
plt.tight_layout()

# Save the plot to a file
output_segmented_plot_path = "mapped_plot_median.pdf"
plt.savefig(output_segmented_plot_path)
plt.show()

print(f"The segmented plot has been saved as {output_segmented_plot_path}")

