if ! type "VBoxClient" &> /dev/null; then
    echo "VBoxClient" unavailable, check guest additions
    exit 0
fi

sudo VBoxClient --display
sudo VBoxClient --clipboard