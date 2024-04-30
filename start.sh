#!/bin/bash

# Define your S3 bucket mount point
MOUNT_POINT='/home/ubuntu/s3'
LOCAL_DIR="/home/ubuntu/setup-comfyui/ComfyUI"

PYTHON_BIN="python"
TEMP_DIR="/home/ubuntu/tmp/s3"

S3_IS_EMPTY=0

echo "Mounting S3 bucket..."
s3fs comfy-ui-s3-bucket "$MOUNT_POINT" -o use_cache=/tmp,multireq_max=32,parallel_count=16,nomultipart
#sudo s3fs comfy-ui-s3-bucket ~/s3 -o allow_other,use_cache=/tmp,ensure_diskfree=50000,multireq_max=32,parallel_count=16,nomultipart,max_stat_cache_size=50000,stat_cache_interval_expire=1300000

# Maximum number of attempts to check for the mount
MAX_ATTEMPTS=6

# Time to wait between attempts (in seconds)
SLEEP_SECONDS=10

# Current attempt counter
attempt=1

# Flag to track mount status
is_mounted=0

while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "Attempt $attempt of $MAX_ATTEMPTS: Checking if S3FS bucket is mounted..."

    if mount | grep "on ${MOUNT_POINT} type fuse.s3fs" > /dev/null; then
        echo "S3FS bucket is mounted."
        is_mounted=1
        break
    else
        echo "S3FS bucket is not mounted. Waiting for $SLEEP_SECONDS seconds to try again..."

        # Check if the s3 directory is not empty
        if [ "$(ls -A $MOUNT_POINT)" ]; then
            echo "s3 directory is not empty, copying files..."
            S3_IS_EMPTY=1
            
            # Ensure the temporary directory exists
            mkdir -p "$TEMP_DIR"

            # Copy the contents of the source directory to the temporary directory
            cp -r "$MOUNT_POINT"/* "$TEMP_DIR"

            # At this point, you can do whatever you need with the source directory
            # For example, deleting its contents or modifying them
            # I will just demonstrate with an echo statement
            echo "Contents copied to $TEMP_DIR. Clearing s3 directory..."
            rm -r "$MOUNT_POINT"/*
        else
            echo "s3 directory is empty, no need to save."
        fi

        sleep $SLEEP_SECONDS
        echo "Try mounting S3 bucket again..."
        s3fs comfy-ui-s3-bucket "$MOUNT_POINT" -o use_cache=/tmp,multireq_max=32,parallel_count=16,nomultipart
    fi

    ((attempt++))
done

if [ $is_mounted -eq 1 ]; then
    echo "Executing next command..."
    # Place your command that should run after verification here
    sleep 10

    # Restore tmp file is not empty
    if [ $S3_IS_EMPTY -eq 1 ]; then
        # When ready, restore the contents from the temporary directory back to the source directory
        echo "Restoring files from $TEMP_DIR to $MOUNT_POINT..."
        cp -r "$TEMP_DIR"/* "$MOUNT_POINT"

        # Cleaning up: remove temporary files if needed
        echo "Cleaning up: removing temporary files..."
        rm -r "$TEMP_DIR"/*
    fi

    echo "Starting ComfyUI..."
    "$PYTHON_BIN" "$LOCAL_DIR"/main.py --listen 0.0.0.0 --port 8080 --input-directory "$MOUNT_POINT"/input --output-directory "$MOUNT_POINT"/output

else
    echo "Failed to confirm S3FS bucket mount after $MAX_ATTEMPTS attempts."
    exit 1
fi