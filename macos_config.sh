#!/bin/bash
set -x

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd $DIR/macos_config 
git clone https://github.com/hooke007/MPV_lazy.git --branch main

mv -f MPV_lazy/portable_config/scripts/uosc scripts
mv -f MPV_lazy/portable_config/scripts/input_plus.lua scripts
mv -f MPV_lazy/portable_config/scripts/playlistmanager.lua scripts
mv -f MPV_lazy/portable_config/scripts/save_global_props.lua scripts
mv -f MPV_lazy/portable_config/scripts/thumbfast.lua scripts

mv -f MPV_lazy/portable_config/script-opts/console.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/osc.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/playlistmanager.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/save_global_props.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/stats.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/thumbfast.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/uosc.conf script-opts
mv -f MPV_lazy/portable_config/script-opts/ytdl_hook.conf script-opts
mv -f MPV_lazy/portable_config/fonts ./

rm -rf MPV_lazy

curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/scripts/SmartCopyPaste_II.lua 
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/script-opts/SmartCopyPaste_II.conf 
mv -f ./SmartCopyPaste_II.lua scripts
mv -f ./SmartCopyPaste_II.conf script-opts
