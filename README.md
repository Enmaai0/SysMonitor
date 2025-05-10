# SysMonitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

SysMonitor is a comprehensive system monitoring and reporting tool written in Bash with optional Python visualization. It provides insights into system resource usage, alerts on threshold breaches, and generates reports and visualizations.

## Features

- Real-time monitoring of CPU, memory, and disk usage
- Detailed reports with system information and top resource-consuming processes
- CSV data export for further analysis
- Python-based visualization of resource usage
- Email alerts when resource usage exceeds defined thresholds
- Configurable thresholds and settings
- Cross-platform support (Linux and macOS)

## Requirements

### Core functionality
- Bash (version 4.0 or higher)
- Common utilities: 
  - Linux: top, df, free, grep, awk, sed
  - macOS: top, df, grep, awk, sed, bc
- mail command (for email alerts)

### Visualization (Optional)
- Python 3.6 or higher
- matplotlib

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Enmaai0/SysMonitor.git
   cd SysMonitor