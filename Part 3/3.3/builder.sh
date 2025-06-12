#!/bin/bash

# --- Shell Script for Cloning, Building, and Publishing Docker Images ---
# This script automates the process of fetching a GitHub repository,
# building a Docker image from a Dockerfile located at the repository's root,
# and then pushing that image to Docker Hub.

# --- Configuration & Variables ---
# Use a temporary directory for cloning the repository to avoid conflicts.
TEMP_DIR="temp_repo_$(date +%s)"

# --- Functions for Error Handling ---
# Function to print an error message and exit
function error_exit {
    echo "Error: $1" >&2
    # Clean up the temporary directory if it exists
    if [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
    exit 1
}

# --- Get User Inputs ---
echo "--- Docker Image Build and Publish Script ---"
echo "Please provide the following information:"

# 1. GitHub Repository URL
read -p "GitHub Repository URL (e.g., https://github.com/owner/repo.git): " GITHUB_REPO_URL
[ -z "$GITHUB_REPO_URL" ] && error_exit "GitHub Repository URL cannot be empty."

# 2. Docker Hub Username
read -p "Docker Hub Username: " DOCKER_USERNAME
[ -z "$DOCKER_USERNAME" ] && error_exit "Docker Hub Username cannot be empty."

# 3. Docker Hub Password/Personal Access Token (PAT)
# Use -s for silent input (no echo) for security
read -s -p "Docker Hub Password/PAT: " DOCKER_PASSWORD
echo # Add a newline after silent input
[ -z "$DOCKER_PASSWORD" ] && error_exit "Docker Hub Password/PAT cannot be empty."

# 4. Desired Docker Image Name (e.g., yourusername/your-app)
read -p "Docker Image Name (e.g., myusername/my-app): " IMAGE_NAME
[ -z "$IMAGE_NAME" ] && error_exit "Docker Image Name cannot be empty."

# 5. Desired Image Tag (e.g., latest, v1.0)
read -p "Docker Image Tag (e.g., latest): " IMAGE_TAG
[ -z "$IMAGE_TAG" ] && IMAGE_TAG="latest" # Default to 'latest' if empty

FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"

echo "--------------------------------------------------"
echo "Starting deployment process..."
echo "GitHub Repo: $GITHUB_REPO_URL"
echo "Docker Image: $FULL_IMAGE_NAME"
echo "--------------------------------------------------"

# --- Step 1: Clone the GitHub Repository ---
echo "Cloning repository from $GITHUB_REPO_URL into $TEMP_DIR..."
if ! git clone "$GITHUB_REPO_URL" "$TEMP_DIR"; then
    error_exit "Failed to clone repository. Check URL and connectivity."
fi
echo "Repository cloned successfully."

# Navigate into the cloned repository directory
if ! cd "$TEMP_DIR"; then
    error_exit "Failed to navigate into cloned repository directory."
fi
echo "Changed directory to $PWD"

# --- Step 2: Build the Docker Image ---
# Assumes Dockerfile is in the root of the cloned repository (current directory '.')
echo "Building Docker image: $FULL_IMAGE_NAME from Dockerfile in $PWD..."
if ! docker build -t "$FULL_IMAGE_NAME" .; then
    # Return to the previous directory before exiting for proper cleanup
    cd - > /dev/null
    error_exit "Failed to build Docker image. Check your Dockerfile and context."
fi
echo "Docker image built successfully."

# --- Step 3: Log in to Docker Hub ---
echo "Logging in to Docker Hub as $DOCKER_USERNAME..."
# Use echo piped to docker login --password-stdin for secure password handling
if ! echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
    # Return to the previous directory before exiting for proper cleanup
    cd - > /dev/null
    error_exit "Failed to log in to Docker Hub. Check your username and password/PAT."
fi
echo "Successfully logged in to Docker Hub."

# --- Step 4: Push the Docker Image to Docker Hub ---
echo "Pushing Docker image $FULL_IMAGE_NAME to Docker Hub..."
if ! docker push "$FULL_IMAGE_NAME"; then
    # Return to the previous directory before exiting for proper cleanup
    cd - > /dev/null
    error_exit "Failed to push Docker image. Check image name, tag, and permissions."
fi
echo "Docker image pushed successfully."

# --- Cleanup ---
echo "Logging out from Docker Hub..."
docker logout > /dev/null 2>&1 # Logout silently

# Return to the directory where the script was run from for proper cleanup
cd - > /dev/null
echo "Cleaning up temporary repository directory: $TEMP_DIR"
if ! rm -rf "$TEMP_DIR"; then
    echo "Warning: Failed to remove temporary directory $TEMP_DIR. Please remove it manually."
else
    echo "Cleanup complete."
fi

echo "--- Script finished successfully! ---"
