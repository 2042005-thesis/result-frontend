#!/bin/bash
set -e  # Exit on error

# Determine the correct docker-compose file to update
if [[ "${GITHUB_REF}" == "refs/heads/dev" ]]; then
  COMPOSE_FILE="apps/dev/docker-compose.yml"
  BRANCH="dev"
  ALLOW_UPDATE=true  # Always allow updates for dev (Git SHA)
fi

if [[ "${GITHUB_REF}" == "refs/heads/staging" ]]; then
  COMPOSE_FILE="apps/staging/docker-compose.yml"
  BRANCH="staging"

elif [[ "${GITHUB_REF}" == refs/tags/v* ]]; then
  # Extract the version from the tag (e.g., v1.2.3)
  BRANCH="main"
  VERSION_TAG="${GITHUB_REF#refs/tags/}"
  ALLOW_UPDATE=true

  # Allow update only if it's a stable semantic version (vX.Y.Z)
  if [[ "$VERSION_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    COMPOSE_FILE="apps/production/docker-compose.yml"
    BRANCH="main"
    ALLOW_UPDATE=true
  else
    echo "Skipping update: Tag '$VERSION_TAG' is not a stable semantic version."
    exit 0
  fi

  # Ensure we are on the main branch
  # Clonning deployment repository
  git clone "$DEPLOYMET_REPO"
  git fetch origin dev  # Fetch latest main branch
  git checkout dev || git checkout -b dev origin/dev  # Switch to main branch
  git reset --hard origin/dev  # Ensure branch is up to date

else
  echo "Branch not recognized, skipping update."
  exit 0
fi

# Proceed only if updates are allowed
if [[ "$ALLOW_UPDATE" == "true" ]]; then
  # Configure Git credentials
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"

  # Update docker image tag in docker-compose.yml
  # Matching
  echo "Updating $COMPOSE_FILE with image: $DOCKER_METADATA_OUTPUT_VERSION"
  sed -E -i "s|(image: $DEPLOYMENT_IMAGE_NAME\s*)[^ ]+|\1$DOCKER_METADATA_OUTPUT_TAGS|" "$COMPOSE_FILE"

  # Stage changes
  git add "$COMPOSE_FILE"

  # Check if there are changes before committing
  if git diff --cached --quiet; then
    echo "No changes to commit, skipping push."
    exit 0  # Exit gracefully instead of failing
  fi

  # Commit and push changes
  git commit -m "Update image tag $DOCKER_METADATA_OUTPUT_VERSION"
  git push origin "$BRANCH"
else
  echo "Skipping update: No valid SHA or stable semantic version detected."
fi
