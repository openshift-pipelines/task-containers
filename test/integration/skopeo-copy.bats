#!/usr/bin/env bats


# Set up test environment

source ./test/helper/helper.sh


# Deploy task to test environment
kubectl apply -f templates/task-sc.yaml


# Define test case
read -p "Enter source registry URL: " source_registry
read -p "Enter destination registry URL: " destination_registry
read -p "Enter source registry username: " source_auth_username
read -p "Enter source registry password: " -s source_auth_password
echo
read -p "Enter destination registry username: " destination_auth_username
read -p "Enter destination registry password: " -s destination_auth_password
echo  "Credentials are taken as input"

# Execute test case
tkn task start skopeo-copy \
    -p SOURCE_REGISTRY="$source_registry" \
    -p DESTINATION_REGISTRY="$destination_registry" \
    -p SOURCE_AUTH_USERNAME="$source_auth_username" \
    -p SOURCE_AUTH_PASSWORD="$source_auth_password" \
    -p DESTINATION_AUTH_USERNAME="$destination_auth_username" \
    -p DESTINATION_AUTH_PASSWORD="$destination_auth_password"

# Verify result
destination_image=$(skopeo inspect docker://$destination_registry | jq -r '.RepoTags[0]')
if [ "$destination_image" != "$destination_registry" ]; then
    echo "Integration test failed: Image was not copied to destination registry"
    assert failure
    exit 1
else
    echo "Integration test passed"
    assert success
fi


# Clean up test environment
kubectl delete -f templates/task-sc.yaml
