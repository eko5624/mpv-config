#!/bin/bash
set -x

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

mkdir -p $DIR/thumbfast+uosc/scripts
mkdir -p $DIR/thumbfast+uosc/script-opts

cd $DIR/thumbfast+uosc

# get thumbfast
git clone https://github.com/po5/thumbfast.git --branch master
mv thumbfast/thumbfast.lua scripts  
mv thumbfast/thumbfast.conf script-opts
rm -rf thumbfast  

# get uosc
git clone https://github.com/tomasklaen/uosc.git --branch main
mv uosc/fonts ./
mv uosc/scripts/* scripts
mv uosc/script-opts/uosc.conf script-opts
rm -rf uosc
