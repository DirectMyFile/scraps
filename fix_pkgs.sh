#!/usr/bin/env bash

DIRS=$(find . -type d | grep -v "packages" | grep -v ".git" | grep -v ".pub" | grep -v ".idea" | grep -v "\.$")

for dir in ${DIRS}
do
  if [ ! -e ${dir}/packages ]
  then
    ln -s ${PWD}/packages ${dir}/packages
  fi
done
