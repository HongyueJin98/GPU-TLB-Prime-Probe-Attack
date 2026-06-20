import pandas as pd
import numpy as np

# CSV file paths
INPUT_CSV = "mapping_table.csv"
OUTPUT_FITTED = "fitted_values_0_8.csv"
OUTPUT_BOUNDARIES = "decision_boundaries.csv"


def least_squares_fit(x, y):
    """
    Performs least squares fitting to find the best-fit line y = ax + b.
    """
    n = len(x)
    sum_x, sum_y = np.sum(x), np.sum(y)
    sum_x2, sum_xy = np.sum(x ** 2), np.sum(x * y)
    
    a = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x ** 2)
    b = (sum_y - a * sum_x) / n
    return a, b


def load_and_clean_data(file_path):
    """
    Reads and filters the CSV file to retain only valid entries.
    """
    data = pd.read_csv(file_path, index_col=0)
    data = data[data.index >= 0]  # Remove invalid rows
    return data.loc[:, "0":"255"]  # Keep columns 0-255


def process_data(data):
    """
    Fits a line for each column and computes values for evicted nums 0-8.
    """
    evicted_nums = np.arange(9)
    fitted_values = pd.DataFrame(index=evicted_nums, columns=data.columns)
    
    for col in data.columns:
        col_data = data[col].dropna()
        if len(col_data) < 2:
            continue
        
        x, y = col_data.index.to_numpy(), col_data.to_numpy()
        a, b = least_squares_fit(x, y)
        fitted_values[col] = a * evicted_nums + b
    
    return fitted_values


def calculate_decision_boundaries(data):
    """
    Computes decision boundaries using midpoints between adjacent evicted nums.
    """
    boundary_table = pd.DataFrame(columns=data.columns)
    
    for col in data.columns:
        col_data = data[col]
        boundaries = [(col_data.iloc[i] + col_data.iloc[i + 1]) / 2 for i in range(len(col_data) - 1)]
        boundaries.append(col_data.iloc[-1])  # Max boundary
        boundary_table[col] = boundaries
    
    boundary_table.index = [str(i) for i in range(len(boundaries) - 1)] + ["Max"]
    return boundary_table


def main():
    # Load and clean data
    data = load_and_clean_data(INPUT_CSV)
    
    # Fit values and save
    fitted_values = process_data(data)
    fitted_values.to_csv(OUTPUT_FITTED, index_label="Evicted Num")
    print(f"Fitted values saved to {OUTPUT_FITTED}")
    
    # Compute decision boundaries
    boundary_table = calculate_decision_boundaries(pd.read_csv(OUTPUT_FITTED, index_col=0))
    boundary_table.to_csv(OUTPUT_BOUNDARIES, index_label="Evicted Num")
    print(f"Decision boundaries saved to {OUTPUT_BOUNDARIES}")


if __name__ == "__main__":
    main()

