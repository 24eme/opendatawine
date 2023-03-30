#!/bin/bash

hashgithubpages=$(git log --oneline githubpages | head -n 1 | awk '{print $1}')
hashmaster=$(git log --oneline master | head -n 1 | awk '{print $1}')
git switch githubpages
git reset $hashmaster
git checkout bin carte.html CNAME communes.html denominations denominations.csv denominations.html index.html LICENSE
rm -rf delimitation_aoc
git reset $hashgithubpages
git checkout .gitignore
git add bin carte.html CNAME communes.html denominations denominations.csv denominations.html index.html LICENSE
git commit -m 'Manual merge branch master ('$hashmaster') into githubpages'
git switch master

