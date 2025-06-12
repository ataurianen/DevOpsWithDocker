#!/bin/bash

# --- Dockerized Script for Cloning, Building, and Publishing Docker Images ---
# This script is designed to run inside a Docker container.
# It expects Docker Hub credentials as environment variables and
# GitHub repo and Docker Hub image details as command-line arguments.

# --- Configuration & Variables ---
# Use a temporary directory for cloning the repository to avoid conflicts.
# Note: This temp directory will be inside the container's filesystem.
TEMP_DIR="/tmp/repo_clone_$(date +%s)"

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

# --- Get Inputs from Environment Variables and Arguments ---
# Docker Hub Credentials (from environment variables)
DOCKER_USERNAME="$DOCKER_USER"
DOCKER_PASSWORD="$DOCKER_PWD"

# GitHub Repo URL (from first argument)
# Expects "owner/repo" format, constructs full URL
GITHUB_REPO_SLUG="$1"
# Default to "latest" tag if not provided as a third argument, otherwise use it
DOCKER_IMAGE_TARGET="$2" # This will be the Docker Hub image name, e.g., mluukkai/testing

# Optional third argument for Docker image tag, defaults to latest
IMAGE_TAG="${3:-latest}"

# --- Input Validation ---
[ -z "$DOCKER_USERNAME" ] && error_exit "DOCKER_USER environment variable is not set."
[ -z "$DOCKER_PASSWORD" ] && error_exit "DOCKER_PWD environment variable is not set."
[ -z "$GITHUB_REPO_SLUG" ] && error_exit "GitHub repository slug (e.g., owner/repo) is required as the first argument."
[ -z "$DOCKER_IMAGE_TARGET" ] && error_exit "Docker Hub image name (e.g., myusername/my-app) is required as the second argument."

# Construct the full GitHub repository URL
# Assumes GitHub.com for simplicity based on prompt's example
GITHUB_REPO_URL="https://github.com/${GITHUB_REPO_SLUG}.git"
FULL_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_TARGET}:${IMAGE_TAG}"

echo "--------------------------------------------------"
echo "--- Docker Image Build and Publish Process ---"
echo "GitHub Repo: $GITHUB_REPO_URL"
echo "Docker Hub User: $DOCKER_USERNAME"
echo "Target Docker Image: $FULL_DOCKER_IMAGE_NAME"
echo "--------------------------------------------------"

# --- Step 1: Clone the GitHub Repository ---
echo "Cloning repository from $GITHUB_REPO_URL into $TEMP_DIR..."
if ! git clone "$GITHUB_REPO_URL" "$TEMP_DIR"; then
    error_exit "Failed to clone repository. Check URL and connectivity within the container."
fi
echo "Repository cloned successfully."

# Navigate into the cloned repository directory
if ! cd "$TEMP_DIR"; then
    error_exit "Failed to navigate into cloned repository directory."
fi
echo "Changed current directory to $PWD (inside container)"

# --- Step 2: Build the Docker Image ---
# Assumes Dockerfile is in the root of the cloned repository (current directory '.')
echo "Building Docker image: $FULL_DOCKER_IMAGE_NAME from Dockerfile in $PWD..."
# The 'docker' command here interacts with the host's Docker daemon via the mounted socket
if ! docker build -t "$FULL_DOCKER_IMAGE_NAME" .; then
    cd - > /dev/null # Go back to previous dir before exiting
    error_exit "Failed to build Docker image. Check your Dockerfile and context."
fi
echo "Docker image built successfully."

# --- Step 3: Log in to Docker Hub ---
echo "Logging in to Docker Hub as $DOCKER_USERNAME..."
# Use echo piped to docker login --password-stdin for secure password handling
if ! echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
    cd - > /dev/null # Go back to previous dir before exiting
    error_exit "Failed to log in to Docker Hub. Check your username and password/PAT."
fi
echo "Successfully logged in to Docker Hub."

# --- Step 4: Push the Docker Image to Docker Hub ---
echo "Pushing Docker image $FULL_DOCKER_IMAGE_NAME to Docker Hub..."
if ! docker push "$FULL_DOCKER_IMAGE_NAME"; then
    cd - > /dev/null # Go back to previous dir before exiting
    error_exit "Failed to push Docker image. Check image name, tag, and permissions."
fi
echo "Docker image pushed successfully."

# --- Cleanup ---
echo "Logging out from Docker Hub..."
docker logout > /dev/null 2>&1 # Logout silently

# Return to the initial directory for proper cleanup
cd / > /dev/null
echo "Cleaning up temporary repository directory: $TEMP_DIR"
if ! rm -rf "$TEMP_DIR"; then
    echo "Warning: Failed to remove temporary directory $TEMP_DIR. Please remove it manually if necessary."
else
    echo "Cleanup complete."
fi

echo "--- Script finished successfully! ---"
