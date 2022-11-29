#!/bin/bash
set -x

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

rm -rf $DIR/portable_config
mkdir -p $DIR/portable_config/script
mkdir -p $DIR/portable_config/script-opts
cd $DIR/portable_config
git clone https://github.com/hooke007/MPV_lazy.git --branch main

rm -rf scripts/uosc
cp -f MPV_lazy/portable_config/scripts/input_plus.lua scripts
cp -f MPV_lazy/portable_config/scripts/load_plus.lua scripts
cp -f MPV_lazy/portable_config/scripts/playlistmanager.lua scripts
cp -f MPV_lazy/portable_config/scripts/save_global_props.lua scripts
cp -f MPV_lazy/portable_config/scripts/thumbfast.lua scripts
cp -r MPV_lazy/portable_config/scripts/uosc scripts

# A temporary workaround for some submenus text of uosc not rendered.
sed -i 's/text_width_estimation = true/text_width_estimation = false/' scripts/uosc/main.lua

# Change to 4× speed play.
sed -i 's/"speed", 2/"speed", 4/' scripts/input_plus.lua

# Change 'stats' icon from 'info_outline' to 'analytics'.  
sed -i 's/command:info_outline/command:analytics/' scripts/uosc/elements/Controls.lua

# Change 'play/pause' icon from 'play_circle/pause_circle' to 'play_arrow/pause'.
sed -i 's/cycle:not_started:pause:no=play_circle\/yes=pause_circle/cycle:play_arrow:pause:no=pause\/yes=play_arrow/' scripts/uosc/elements/Controls.lua

# Change 'open file' icon from 'file_open' to 'folder'.
sed -i 's/command:file_open/command:folder/' scripts/uosc/elements/Controls.lua

cp -f MPV_lazy/portable_config/script-opts/console.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/load_plus.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/osc.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/playlistmanager.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/save_global_props.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/stats.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/thumbfast.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/uosc.conf script-opts
cp -f MPV_lazy/portable_config/script-opts/ytdl_hook.conf script-opts

# Don't dim screen when triggering menu.
sed -i 's/curtain_opacity=0.5/curtain_opacity=0/' script-opts/uosc.conf

# Add 'prev/next chapter' button and 'open-file' button.
sed -i 's/gap,play_pause,gap/open-file,gap,<has_chapter>command:skip_previous:add chapter -1?上一章节,play_pause,<has_chapter>command:skip_next:add chapter 1?下一章节,gap/' script-opts/uosc.conf

#Change thumb size from 300px to 360px
sed -i 's/max_height=300/max_height=360/' script-opts/thumbfast.conf
sed -i 's/max_width=300/max_width=360/' script-opts/thumbfast.conf

cp -r MPV_lazy/portable_config/fonts ./
cp -r MPV_lazy/portable_config/luts ./
cp -r MPV_lazy/portable_config/vs ./

rm -rf MPV_lazy

curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/scripts/SmartCopyPaste_II.lua 
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/script-opts/SmartCopyPaste_II.conf 
mv -f ./SmartCopyPaste_II.lua scripts
mv -f ./SmartCopyPaste_II.conf script-opts
