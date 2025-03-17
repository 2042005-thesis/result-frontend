#!/bin/bash
# Determine the correct docker-compose file to update
if [[ "${GITHUB_REF}" == "refs/heads/staging" ]]; then
  COMPOSE_FILE="env/staging/docker-compose.yml"
elif [[ "${GITHUB_REF}" == refs/tags/v* ]]; then
  COMPOSE_FILE="env/production/docker-compose.yml"
else
  echo "Branch not recognized, skipping update."
  exit 0
fi

# Configure Git credentials
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

# Update docker image tag in docker-compose.yml
echo "Updating $COMPOSE_FILE with image: $DOCKER_METADATA_OUTPUT_VERSION"
sed -E -i "s|(image:\s*)[^ ]+|\1$DOCKER_METADATA_OUTPUT_TAGS|" "$COMPOSE_FILE"

# Stage changes
git add "$COMPOSE_FILE"
git commit -m "Update image tag $DOCKER_METADATA_OUTPUT_VERSION"

# Check if there are changes before committing
if [[ "git diff --cached --quiet" ]]; then
  echo "No changes to commit, skipping push."
  exit 0  # Exit gracefully instead of failing
elif [[ "${GITHUB_REF}" == "refs/heads/staging" ]]; then
  git push
elif [[ "${GITHUB_REF}" == refs/tags/v* ]]; then
  git push origin main
else
  echo "Branch not recognized, failed update."
  exit 1
fi