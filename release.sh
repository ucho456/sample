#!/bin/bash

get_current_version() {
  current_version=$(cat package.json | grep -oP '"version": "\K[^"]+')
  echo "$current_version"
}

if [ $# -ne 1 ]; then
  echo "Usage: $0 <major|minor|patch>"
  exit 1
fi

version_up_type=$1

git stash push --keep-index

git checkout dev

git pull origin dev

current_version=$(get_current_version)

IFS='.' read -ra version_parts <<< "$current_version"

major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

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

new_version="$major.$minor.$patch"

sed -i "s/\"version\": \"$current_version\"/\"version\": \"$new_version\"/" package.json

git add package.json

git commit -m "Release version $new_version"

git add package.json

git commit -m "Release version $new_version"

git checkout main

git pull origin main

git merge dev

git tag -a v$new_version -m "Release version $new_version"

git push origin v$new_version

git push origin main

git branch -d release-$new_version

git stash pop

git checkout dev

git push origin dev

echo "Version $new_version has been released."
