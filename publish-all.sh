#!/bin/bash
# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

echo "Publishing all..."

./publish-web.sh
./publish-windows.sh

echo "All versions are published successfully!"