#!/bin/bash

# Besten Server finden und testen
best_server=$(curl -s 'https://www.speedtest.net/api/js/servers?engine=js&search=thessaloniki' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -n "$best_server" ]; then
    speedtest-cli --simple --server "$best_server" 2>/dev/null | grep Download | awk '{print $2 " Mbps"}'
else
    speedtest-cli --simple 2>/dev/null | grep Download | awk '{print $2 " Mbps"}'
fi
