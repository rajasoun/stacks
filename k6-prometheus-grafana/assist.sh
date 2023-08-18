#!/usr/bin/env bash

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Function to print a horizontal line for better visibility in logs
function print_line() {
    echo "--------------------------------------------------------------------------------------"
}

# Function to print error messages in red
function print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to print success messages in green
function print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to start services with docker-compose
function start_services() {
    echo "Starting prometheus and Grafana services..."

    if ! docker-compose -f "${PWD}/docker-compose.yml" up -d prometheus grafana; then
        print_error "Error starting services. Please check if the ports are available or try restarting Docker."
        exit 1
    fi
}

# Function to stop services
function stop_services() {
    echo "Stopping prometheus and Grafana services..."
    docker-compose -f "${PWD}/docker-compose.yml" down
    print_success "Services stopped successfully!"
}

# Function to check services status
function services_status() {
    docker-compose -f "${PWD}/docker-compose.yml" ps
}

# Function to check if a service is operational
function wait_for_service() {
    local url="$1"
    local timeout="${2:-30}"  # default to 30 seconds if not provided

    echo -n "Checking if service at $url is operational... "
    
    for ((i=0; i<$timeout; i++)); do
        if curl --silent --fail "$url" > /dev/null; then
            print_success "Operational!"
            return 0
        fi

        echo -n "."
        sleep 1
    done

    print_error "Failed!"
    echo "Error: Service at $url did not become operational after $timeout seconds."
    exit 1
}

# Function to display information about Grafana dashboard
function display_grafana_info() {
    print_line
    echo "Load testing with Grafana dashboard http://localhost:3000/dashboards"
    print_line
}

# Function to run the K6 load test
function run_k6_test() {
   echo "Running K6 load test..."
   #K6_BROWSER_ENABLED=true K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true k6 run -o experimental-prometheus-rw --tag testid=12345 scripts/tests/all.js
   #K6_BROWSER_ENABLED=true K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true k6 run -o experimental-prometheus-rw --tag testid=12345 scripts/tests/loginFlowTest.js
   K6_BROWSER_HEADLESS=false K6_BROWSER_ENABLED=true K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true k6 run -o experimental-prometheus-rw --tag testid=15082023 
}

# Main execution sequence based on user input
function main() {
    case "$1" in
        start)
            start_services
            wait_for_service "http://localhost:9090/-/healthy"      # Checking prometheus
            wait_for_service "http://localhost:3000/api/health"  # Checking Grafana
            display_grafana_info
            ;;
        stop)
            stop_services
            ;;
        status)
            services_status
            ;;
        load)
            run_k6_test
            ;;
        *)
            echo "Usage: $0 {start|stop|status|load}"
            exit 1
            ;;
    esac
}

# Start the script execution with user input
main "$@"
