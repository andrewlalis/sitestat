#!/usr/bin/env bash
# A personal script I use to deploy a sitestat instance to andrewlalis.com

echo "Building sitestat"
dub clean
dub build --build=release --compiler=/opt/ldc2/ldc2-1.33.0-linux-x86_64/bin/ldc2

echo "Deploying to andrewlalis.com"
ssh -f root@andrewlalis.com 'systemctl stop sitestat.service'
scp sitestat root@andrewlalis.com:/opt/sitestat/
ssh -f root@andrewlalis.com 'systemctl start sitestat.service'
echo "Done!"
