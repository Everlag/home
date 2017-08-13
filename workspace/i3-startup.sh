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
#
# We open chrome with specific urls based off of whether or not
# we can detect the presence of desired extensions in the Extension
# directory for chromium.
#
# Hence, first boot will yield all the store pages to install the
# extensions and future boots will not.
extensions=(
    'vimium https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb?hl=en'
    'ublock-origin https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm?hl=en'
    'session-buddy https://chrome.google.com/webstore/detail/session-buddy/edacconmaakjimmfgnblocblbcdcpbko?hl=en'
)
to_open=''
for i in "${extensions[@]}"; do
    # Look for the string in the correct directory
    search_string=$(echo ${i} | awk '{print $1;}')
    url=$(echo ${i} | awk '{print $2;}')
    found=$(grep -rF -o ${search_string} \
        /home/vagrant/.config/chromium/Default/Extensions/ |
        head -n1)
    # Not found, add it to the urls to open
    if [ -z ${found} ]; then
        to_open="${to_open} ${url}"
    fi
done
nohup chromium-browser --disable-smooth-scrolling ${to_open} &

# Code
nohup code &