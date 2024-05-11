#!/bin/bash
# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

echo "Publishing to web..."

truncate -s 0 publish.log
mkdir -p exports/web

echo "Building web version..."

output=$(godot --headless --export-release Web exports/web/index.html > /dev/null 2>&1)

if [ $? -eq 0 ]; then
    echo "" > publish.log
    echo "$output" > publish.log
    echo "" > publish.log
    echo "Web version is built successfully."
else
    echo "$output"
    echo "Couldn't build web version!"
    exit 1
fi

echo "Uploading..."

rsync -ru exports/web/* root@meowingcat.io:/opt/meowingcat.io/webroot/projects/poker/play

echo "Removing local build..."

rm -rf exports/web/*

echo "Published successfully!"
