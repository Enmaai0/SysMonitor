#!/usr/bin/env python3
#
# Visualization script for SysMonitor
# Author: Enmaai0
# License: MIT

import sys
import os
import csv
import matplotlib.pyplot as plt
from datetime import datetime

def read_csv_data(csv_file):
    """Read data from CSV file"""
    metrics = {}
    
    try:
        with open(csv_file, 'r') as file:
            reader = csv.DictReader(file)
            for row in reader:
                metrics[row['metric']] = float(row['value'])
        return metrics
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return None

def generate_visualization(csv_file):
    """Generate visualization from CSV data"""
    metrics = read_csv_data(csv_file)
    
    if not metrics:
        print("No data to visualize")
        return False
    
    # Create output directory for visualizations
    output_dir = os.path.join(os.path.dirname(csv_file), 'visualizations')
    os.makedirs(output_dir, exist_ok=True)
    
    # Extract timestamp from CSV filename
    timestamp = os.path.basename(csv_file).replace('data_', '').replace('.csv', '')
    
    # Create a bar chart for CPU, memory, and disk usage
    fig, ax = plt.subplots(figsize=(10, 6))
    
    labels = list(metrics.keys())
    values = list(metrics.values())
    
    bars = ax.bar(labels, values, color=['#3498db', '#2ecc71', '#e74c3c'])
    
    # Add threshold lines
    thresholds = {'cpu': 80, 'memory': 80, 'disk': 90}
    for i, (metric, threshold) in enumerate(thresholds.items()):
        if metric in metrics:
            plt.axhline(y=threshold, color='r', linestyle='--', alpha=0.7)
    
    # Add labels and title
    ax.set_xlabel('Metrics')
    ax.set_ylabel('Usage (%)')
    ax.set_title(f'System Resource Usage - {timestamp.replace("_", " ")}')
    
    # Add value labels on bars
    for bar in bars:
        height = bar.get_height()
        ax.annotate(f'{height:.2f}%',
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3),
                    textcoords="offset points",
                    ha='center', va='bottom')
    
    # Set y-axis to go from 0 to 100
    ax.set_ylim(0, 100)
    
    # Add grid
    ax.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Save visualization
    output_file = os.path.join(output_dir, f'visualization_{timestamp}.png')
    plt.savefig(output_file)
    print(f"Visualization saved to {output_file}")
    
    return True

if __name__ == "__main__":
    # Check arguments
    if len(sys.argv) != 2:
        print("Usage: visualize.py <csv_file>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    
    # Check if file exists
    if not os.path.isfile(csv_file):
        print(f"Error: File {csv_file} does not exist")
        sys.exit(1)
    
    # Generate visualization
    if generate_visualization(csv_file):
        print("Visualization generated successfully")
    else:
        print("Failed to generate visualization")
        sys.exit(1)