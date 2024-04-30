#!/bin/bash

# The directory to start from, "." means the current directory
# You can replace "." with another directory path if needed
start_dir="/home/ubuntu/setup-comfyui/ComfyUI/custom_nodes/"
pyhton_dir="python"

# Iterate over each directory in the specified start directory (first layer only)
for dir in "$start_dir"/*/; do
    echo "Checking in $dir..."

    # Remove the trailing slash for file existence checks
    dir="${dir%/}"

    # Check if 'requirements.txt' exists in the directory
    if [[ -f "$dir/requirements.txt" ]]; then
        echo "'requirements.txt' found in $dir. Running pip install..."
        # Assuming pip is in the PATH, adjust if necessary
        "$pyhton_dir" -m pip install -r "$dir/requirements.txt"
    fi

    # Check if 'install.py' exists in the directory
    if [[ -f "$dir/install.py" ]]; then
        echo "'install.py' found in $dir. Running the script..."
        # Save current directory and change to the directory containing install.py
        pushd "$dir" > /dev/null
        # Run the install.py script, adjust the python command as necessary
        "$pyhton_dir" install.py
        # Return to the previously saved directory
        popd > /dev/null
    fi
done