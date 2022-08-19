#!/usr/bin/env bash

# Get a count of files for all buckets in your current project, and count how many files are public.
# This might take a while if you think you have millions of files, so this script is not recommended as-is if that's the case.

for bucket in $(gsutil ls)
do
  echo $bucket
  echo $(gsutil du $bucket | wc -l) 'files and folders'
  echo $(gsutil ls -R -L $bucket | grep 'allUsers' -c) 'public files'
done
