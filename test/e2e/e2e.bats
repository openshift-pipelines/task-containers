#!/usr/bin/env bats


# Set up test environment

source ./test/helper/helper.sh


# Deploy task to test environment
kubectl apply -f templates/task-sc.yaml


# Define test case
read -p "Enter source registry URL: " SOURCE_REGISTRY
read -p "Enter destination registry URL: " DESTINATION_REGISTRY
read -p "Enter source registry username: " SOURCE_AUTH_USERNAME
read -p "Enter source registry password: " -s SOURCE_AUTH_PASSWORD
echo  "Source registry Credentials are taken as input"

read -p "Enter destination registry username: " DESTINATION_AUTH_USERNAME
read -p "Enter destination registry password: " -s DESTINATION_AUTH_PASSWORD
echo  "Destination registry Credentials are taken as input"



# Check that the source image exists in the source registry
if ! skopeo inspect --creds "$SOURCE_AUTH_USERNAME:$SOURCE_AUTH_PASSWORD" "docker://$SOURCE_REGISTRY/$SOURCE_IMAGE" >/dev/null 2>&1; then
  echo "Error: Source image does not exist in source registry"
  exit 1
fi

# Run the skopeo-copy task
if ! tkn pipeline start skopeo-copy -p SOURCE_REGISTRY="$SOURCE_REGISTRY" \
  -p DESTINATION_REGISTRY="$DESTINATION_REGISTRY" \
  -p SOURCE_AUTH_USERNAME="$SOURCE_AUTH_USERNAME" \
  -p SOURCE_AUTH_PASSWORD="$SOURCE_AUTH_PASSWORD" \
  -p DESTINATION_AUTH_USERNAME="$DESTINATION_AUTH_USERNAME" \
  -p DESTINATION_AUTH_PASSWORD="$DESTINATION_AUTH_PASSWORD"; then
  echo "Error: Failed to run skopeo-copy task"
  assert failure
  exit 1
fi

# Check that the image was copied to the destination registry
if ! skopeo inspect --creds "$DESTINATION_AUTH_USERNAME:$DESTINATION_AUTH_PASSWORD" "docker://$DESTINATION_REGISTRY/$SOURCE_IMAGE" >/dev/null 2>&1; then
  echo "Error: Image was not copied to destination registry"
  assert failure
  exit 1
fi

# Check that the image in the destination registry is the same as the image in the source registry
if ! skopeo inspect --creds "$SOURCE_AUTH_USERNAME:$SOURCE_AUTH_PASSWORD" "docker://$SOURCE_REGISTRY/$SOURCE_IMAGE" | diff - <(skopeo inspect --creds "$DESTINATION_AUTH_USERNAME:$DESTINATION_AUTH_PASSWORD" "docker://$DESTINATION_REGISTRY/$SOURCE_IMAGE"); then
  echo "Error: Image in destination registry is not the same as image in source registry"
  assert failure
  exit 1
fi

# Check that the correct authentication credentials were used for both the source and destination registries
if ! skopeo inspect --creds "$SOURCE_AUTH_USERNAME:$SOURCE_AUTH_PASSWORD" "docker://$SOURCE_REGISTRY/$SOURCE_IMAGE" >/dev/null 2>&1 && skopeo inspect --creds "$DESTINATION_AUTH_USERNAME:$DESTINATION_AUTH_PASSWORD" "docker://$DESTINATION_REGISTRY/$SOURCE_IMAGE" >/dev/null 2>&1; then
  echo "Error: Authentication credentials are incorrect"
  assert failure
  exit 1
fi

echo "e2e test completed successfully"
assert success

# Clean up test environment
kubectl delete -f templates/task-sc.yaml