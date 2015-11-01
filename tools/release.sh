#!/bin/bash

echo "Type the release number for this release: [1.2.3.MooseBuild]"

read version_str

read -r -p "Proceed with bundle update? [Y/n] " bundle_update
if [[ ${bundle_update:-Y} =~ ^([Yy])$ ]]
then
  bundle update
  git diff --quiet ../Gemfile.lock
  if [[ $? -ne 0 ]]
  then
    git commit ../Gemfile.lock -m "Update Gems for ${version_str}."
  else
    echo "No gems updates found."
  fi
fi

read -r -p "Proceed with version bump? [Y/n] " version_bump
if [[ ${version_bump:-Y} =~ ^([Yy])$ ]]
then
  IFS='.' read -a version <<< "$version_str"
  if [[ ${version[3]}  == '' ]]
  then
    version[3]=nil
  else
    version[3]=`echo \'${version[3]}\' | tr '[A-Z]' '[a-z]'`
  fi

  sed -i '' -e "s/MAJOR = .*$/MAJOR = ${version[0]}/" ../lib/concerto/version.rb
  sed -i '' -e "s/MINOR = .*$/MINOR = ${version[1]}/" ../lib/concerto/version.rb
  sed -i '' -e "s/TINY = .*$/TINY = ${version[2]}/" ../lib/concerto/version.rb
  sed -i '' -e "s/PRE = .*$/PRE = ${version[3]}/" ../lib/concerto/version.rb

  git diff --quiet ../lib/concerto/version.rb
  if [[ $? -ne 0 ]]
  then
    git commit ../lib/concerto/version.rb -m "Bump to ${version_str}."
  else
    echo "The version was already bumped."
  fi
fi

read -r -p "Proceed with tag creation? [Y/n] " create_tag
tag=`echo ${version_str} | tr '[A-Z]' '[a-z]'`
if [[ ${create_tag:-Y}  =~ ^([Yy])$ ]]
then
  if git show-ref --tags | egrep -q "refs/tags/$tag$"
  then
    echo "Tag already found."
  else
    git tag -a "${tag}" -m "Release ${tag}."
    echo "Created tag ${tag}."
  fi
fi

echo -e "\nThe release is finished.  You should push using the following commands:\n"
echo "git push origin master"
echo "git push origin ${tag}"
echo -e "\nThank you come again."
