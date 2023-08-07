# Function: Get the version from package.json
get_current_version() {
  current_version=$(cat package.json | grep -oP '"version": "\K[^"]+')
  echo "$current_version"
}

# Check arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <major|minor|patch>"
  exit 1
fi

# Get version update type from arguments
version_up_type=$1

# Switch to the dev branch and update it
git checkout dev
git pull origin dev

# Get current version
current_version=$(get_current_version)

# Split version into an array
IFS='.' read -ra version_parts <<< "$current_version"

# Get major, minor, and patch versions
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

# Version update handling
if [ "$version_up_type" = "major" ]; then
  ((major++))
  minor=0
  patch=0
elif [ "$version_up_type" = "minor" ]; then
  ((minor++))
  patch=0
elif [ "$version_up_type" = "patch" ]; then
  ((patch++))
else
  echo "Invalid version update type."
  exit 1
fi

# Create new version
new_version="$major.$minor.$patch"

# Update the version in package.json
sed -i "s/\"version\": \"$current_version\"/\"version\": \"$new_version\"/" package.json

# Commit the version change
git add package.json
git commit -m "Release version $new_version"

# Create a release branch
git checkout -b release-$new_version

# Commit changes with the new version
git add package.json
git commit -m "Release version $new_version"

# Merge into the dev branch
git checkout dev
git merge release-$new_version

# Merge into the main branch
git checkout main
git merge dev

# Create and push the tag
git tag -a v$new_version -m "Release version $new_version"
git push origin v$new_version

# Push the main branch
git push origin main

# Delete the release branch
git branch -d release-$new_version

echo "Version $new_version has been released."
