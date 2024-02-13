#!/bin/bash

rsync -av --exclude=delimitation_aoc  --exclude=geo --exclude=.gitignore --exclude=.git ../opendatawine_master/ .
