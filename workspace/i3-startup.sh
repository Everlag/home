#!/bin/bash

# This creates all of our workspaces and populates them
# with the programs we want

# Build our workspaces out
for i in {1..3}; do
    i3-msg \
        "workspace ${i}; append_layout /home/vagrant/.i3/workspace-${i}.json"
done

# Start up our shells
#
# We can have a lot of them, so just count
count=$(grep -rF -o '"class": "^URxvt$"' /home/vagrant/.i3/workspace-* \
    | wc -l)
for i in $(seq 1 $count); do
    nohup urxvt &
done

# Chrome
nohup chromium-browser --disable-smooth-scrolling &

# Code
nohup code &