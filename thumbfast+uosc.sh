#!/bin/bash
set -x

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

[ ! -d "$DIR/thumbfast+uosc/scripts" ] || mkdir -p $DIR/thumbfast+uosc/scripts
[ ! -d "$DIR/thumbfast+uosc/script-opts" ] || mkdir -p $DIR/thumbfast+uosc/script-opts

cd $DIR/thumbfast+uosc

# get thumbfast
git clone https://github.com/po5/thumbfast.git --branch master
cp -f thumbfast/thumbfast.lua scripts  
cp -f thumbfast/thumbfast.conf script-opts
rm -rf thumbfast  

# get uosc
git clone https://github.com/tomasklaen/uosc.git --branch main
rm -rf fonts
cp -r uosc/fonts ./
cp -rf uosc/scripts/* scripts
cp -f uosc/script-opts/uosc.conf script-opts
rm -rf uosc
