#!/bin/bash
cd ../../..

for commit in $1;
do
  # shellcheck disable=SC2086
  msg=$(git log --format=%B $commit -1)
  echo "$msg" | commitlint
done
