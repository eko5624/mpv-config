#!/bin/sh
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rm -rf portable_config/scripts && mkdir -p "${DIR}"/portable_config/scripts
rm -rf portable_config/script-opts && mkdir -p "${DIR}"/portable_config/script-opts

cd "${DIR}"/portable_config 
git clone https://github.com/hooke007/MPV_lazy.git --branch main

mv MPV_lazy/portable_config/scripts/contextmenu_gui scripts
mv MPV_lazy/portable_config/scripts/input_plus.lua scripts
mv MPV_lazy/portable_config/scripts/load_plus.lua scripts
mv MPV_lazy/portable_config/scripts/osc_plus.lua scripts
mv MPV_lazy/portable_config/scripts/playlistmanager.lua scripts
mv MPV_lazy/portable_config/scripts/save_global_props.lua scripts
mv MPV_lazy/portable_config/scripts/thumbfast.lua scripts

mv MPV_lazy/portable_config/script-opts/console.conf script-opts
mv MPV_lazy/portable_config/script-opts/contextmenu_gui.conf script-opts
mv MPV_lazy/portable_config/script-opts/contextmenu_gui_engine.conf script-opts
mv MPV_lazy/portable_config/script-opts/load_plus.conf script-opts
mv MPV_lazy/portable_config/script-opts/osc.conf script-opts
mv MPV_lazy/portable_config/script-opts/osc_plus.conf script-opts
mv MPV_lazy/portable_config/script-opts/playlistmanager.conf script-opts
mv MPV_lazy/portable_config/script-opts/save_global_props.conf script-opts
mv MPV_lazy/portable_config/script-opts/stats.conf script-opts
mv MPV_lazy/portable_config/script-opts/thumbfast.conf script-opts
mv MPV_lazy/portable_config/script-opts/ytdl_hook.conf script-opts

rm -rf MPV_lazy

curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/scripts/SmartCopyPaste_II.lua 
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/script-opts/SmartCopyPaste_II.conf 
mv ./SmartCopyPaste_II.lua scripts
mv ./SmartCopyPaste_II.conf script-opts
