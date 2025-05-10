#!/bin/bash
#
# SysMonitor - A comprehensive system monitoring tool
# Author: Enmaai0
# License: MIT

set -e

VERSION="1.0.0"

# Default configuration
CONFIG_FILE="config/config.conf"
OUTPUT_DIR="data"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=80
ALERT_THRESHOLD_DISK=90
EMAIL_ALERTS=false
EMAIL_ADDRESS=""
VISUALIZATION=false

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help message
function show_help {
    echo -e "${BLUE}SysMonitor${NC} - A comprehensive system monitoring tool"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -c, --config FILE     Specify configuration file (default: config/config.conf)"
    echo "  -o, --output DIR      Specify output directory (default: data)"
    echo "  -a, --alerts          Enable email alerts"
    echo "  -e, --email EMAIL     Email address for alerts"
    echo "  -v, --visualization   Generate visualization using Python"
    echo "  -h, --help            Display this help message"
    echo "  -V, --version         Display version information"
    echo
    echo "Examples:"
    echo "  $0 --config my_config.conf"
    echo "  $0 --alerts --email admin@example.com"
    echo
}

# Version information
function show_version {
    echo "SysMonitor version $VERSION"
}

# Check if a command exists
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# Log messages
function log {
    local level=$1
    local message=$2
    local color=$NC
    
    case $level in
        "INFO") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
    esac
    
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${color}${level}${NC}: ${message}"
}

# Check required tools
function check_requirements {
    local missing_tools=()
    local os_type=$(uname)
    
    # Use different Tools for different System
    if [ "$os_type" = "Darwin" ]; then
        # macOS
        for tool in "top" "df" "grep" "awk" "sed"; do
            if ! command_exists "$tool"; then
                missing_tools+=("$tool")
            fi
        done
    else
        # Linux
        for tool in "top" "df" "free" "grep" "awk" "sed"; do
            if ! command_exists "$tool"; then
                missing_tools+=("$tool")
            fi
        done
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    if [ "$VISUALIZATION" = true ] && ! command_exists "python3"; then
        log "ERROR" "Python3 is required for visualization but it's not installed"
        exit 1
    fi
    
    if [ "$EMAIL_ALERTS" = true ]; then
        if ! command_exists "mail"; then
            log "ERROR" "The 'mail' command is required for email alerts but it's not installed"
            exit 1
        fi
        
        if [ -z "$EMAIL_ADDRESS" ]; then
            log "ERROR" "Email address is required for alerts"
            exit 1
        fi
    fi
}

# Parse command line arguments
function parse_arguments {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -a|--alerts)
                EMAIL_ALERTS=true
                shift
                ;;
            -e|--email)
                EMAIL_ADDRESS="$2"
                shift 2
                ;;
            -v|--visualization)
                VISUALIZATION=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -V|--version)
                show_version
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Load configuration file
function load_config {
    if [ -f "$CONFIG_FILE" ]; then
        log "INFO" "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log "WARNING" "Configuration file $CONFIG_FILE not found, using defaults"
    fi
}

# Create output directory if it doesn't exist
function prepare_output_dir {
    if [ ! -d "$OUTPUT_DIR" ]; then
        log "INFO" "Creating output directory: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi
}

# Get CPU usage
function get_cpu_usage {
    local cpu_usage
    local os_type=$(uname)
    
    if [ "$os_type" = "Darwin" ]; then
        # macOS
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    else
        # Linux
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    fi
    
    echo "$cpu_usage"
}

# Get memory usage
function get_memory_usage {
    local memory_usage
    local os_type=$(uname)
    
    if [ "$os_type" = "Darwin" ]; then
        # macOS
        local total_memory=$(sysctl -n hw.memsize)
        local page_size=$(sysctl -n hw.pagesize)
        local vm_stat=$(vm_stat | grep "Pages")
        
        local free_count=$(echo "$vm_stat" | grep "free" | awk '{print $3}' | tr -d '.')
        local inactive_count=$(echo "$vm_stat" | grep "inactive" | awk '{print $3}' | tr -d '.')
        local speculative_count=$(echo "$vm_stat" | grep "speculative" | awk '{print $3}' | tr -d '.')
        
        local free_memory=$(( (free_count + inactive_count + speculative_count) * page_size ))
        memory_usage=$(echo "scale=2; (1 - ($free_memory / $total_memory)) * 100" | bc)
    else
        # Linux
        memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    fi
    
    echo "$memory_usage"
}

# Get disk usage
function get_disk_usage {
    local disk_usage
    disk_usage=$(df -h / | grep / | awk '{print $5}' | tr -d '%')
    echo "$disk_usage"
}

# Get system load average
function get_load_average {
    local load_avg
    load_avg=$(uptime | awk -F'[a-z]:' '{ print $2}' | sed 's/,//g')
    echo "$load_avg"
}

# Get top processes by CPU usage
function get_top_processes_cpu {
    local processes
    local os_type=$(uname)
    
    if [ "$os_type" = "Darwin" ]; then
        # macOS
        processes=$(ps -Ao user,pid,%cpu,%mem,command -r | head -11 | tail -10)
    else
        # Linux
        processes=$(ps aux --sort=-%cpu | head -11 | tail -10)
    fi
    
    echo "$processes"
}

# Get top processes by memory usage
function get_top_processes_memory {
    local processes
    local os_type=$(uname)
    
    if [ "$os_type" = "Darwin" ]; then
        # macOS
        processes=$(ps -Ao user,pid,%cpu,%mem,command -m | head -11 | tail -10)
    else
        # Linux
        processes=$(ps aux --sort=-%mem | head -11 | tail -10)
    fi
    
    echo "$processes"
}

# Generate report
function generate_report {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local report_file="${OUTPUT_DIR}/report_${timestamp}.txt"
    
    log "INFO" "Generating system report to $report_file"
    
    {
        echo "=============== SYSTEM MONITORING REPORT ==============="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo
        
        echo "--------------- SYSTEM RESOURCES ---------------"
        echo "CPU Usage: $(get_cpu_usage)%"
        echo "Memory Usage: $(get_memory_usage | xargs printf "%.2f")%"
        echo "Disk Usage: $(get_disk_usage)%"
        echo "Load Average: $(get_load_average)"
        echo
        
        echo "--------------- TOP CPU PROCESSES ---------------"
        echo "$(ps aux --sort=-%cpu | head -1)"
        echo "$(get_top_processes_cpu)"
        echo
        
        echo "--------------- TOP MEMORY PROCESSES ---------------"
        echo "$(ps aux --sort=-%mem | head -1)"
        echo "$(get_top_processes_memory)"
        echo
        
        echo "=============== END OF REPORT ==============="
    } > "$report_file"
    
    # Also generate CSV data for visualization
    local csv_file="${OUTPUT_DIR}/data_${timestamp}.csv"
    {
        echo "metric,value"
        echo "cpu,$(get_cpu_usage)"
        echo "memory,$(get_memory_usage)"
        echo "disk,$(get_disk_usage)"
    } > "$csv_file"
    
    log "INFO" "Report generated successfully"
    
    # Return the filenames for potential further processing
    echo "$report_file,$csv_file"
}

# Check if any metric exceeds threshold and send alert if needed
function check_alerts {
    local report_file=$1
    local cpu_usage
    local memory_usage
    local disk_usage
    
    cpu_usage=$(get_cpu_usage)
    memory_usage=$(get_memory_usage)
    disk_usage=$(get_disk_usage)
    
    if [ "$EMAIL_ALERTS" = true ] && [ -n "$EMAIL_ADDRESS" ]; then
        local alert_message=""
        local should_alert=false
        
        if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
            alert_message+="WARNING: CPU usage is high (${cpu_usage}%)\n"
            should_alert=true
        fi
        
        if (( $(echo "$memory_usage > $ALERT_THRESHOLD_MEM" | bc -l) )); then
            alert_message+="WARNING: Memory usage is high (${memory_usage}%)\n"
            should_alert=true
        fi
        
        if (( $(echo "$disk_usage > $ALERT_THRESHOLD_DISK" | bc -l) )); then
            alert_message+="WARNING: Disk usage is high (${disk_usage}%)\n"
            should_alert=true
        fi
        
        if [ "$should_alert" = true ]; then
            log "WARNING" "Resource threshold exceeded, sending email alert"
            echo -e "Subject: [ALERT] System resource usage threshold exceeded\n\n$alert_message\nFull report is attached." | 
            mail -a "$report_file" -s "[ALERT] System resource usage threshold exceeded" "$EMAIL_ADDRESS"
        fi
    fi
}

# Generate visualization if Python is available and option is enabled
function generate_visualization {
    local csv_file=$1
    
    if [ "$VISUALIZATION" = true ] && command_exists "python3"; then
        local script_dir
        script_dir=$(dirname "$(readlink -f "$0")")
        local vis_script="${script_dir}/visualize.py"
        
        if [ -f "$vis_script" ]; then
            log "INFO" "Generating visualization using Python"
            python3 "$vis_script" "$csv_file"
        else
            log "ERROR" "Visualization script not found: $vis_script"
        fi
    fi
}

# Main function
function main {
    log "INFO" "Starting SysMonitor"
    
    parse_arguments "$@"
    load_config
    check_requirements
    prepare_output_dir
    
    local files
    files=$(generate_report)
    
    IFS=',' read -r report_file csv_file <<< "$files"
    
    check_alerts "$report_file"
    
    if [ "$VISUALIZATION" = true ]; then
        generate_visualization "$csv_file"
    fi
    
    log "INFO" "SysMonitor completed successfully"
}

# Run the script
main "$@"