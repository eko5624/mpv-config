#!/bin/bash
shopt -s extglob
set -ex

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

rm -rf $DIR/portable_config/fonts
rm -rf $DIR/portable_config/script-opts/!("dyn_menu.conf")
rm -rf $DIR/portable_config/scripts
rm -rf $DIR/portable_config/shaders
mkdir -p $DIR/portable_config/script-opts
mkdir -p $DIR/portable_config/scripts
mkdir -p $DIR/portable_config/fonts

cd $DIR/portable_config

echo "Getting HDR Toys"
echo "======================="
curl -OL https://github.com/natural-harmonia-gropius/hdr-toys/releases/download/v2401/HDR-Toys.v2401.zip
unzip HDR-Toys.v2401.zip
cd "HDR-Toys v2401"
cp -f scripts/hdr-toys-helper.lua ../scripts
cp -f hdr-toys.conf ../
cp -rf shaders ../
cd ..
rm -rf "HDR-Toys v2401"
rm HDR-Toys.v2401.zip

echo "Getting mpv-menu-plugin"
echo "======================="
curl -OL https://github.com/tsl0922/mpv-menu-plugin/releases/latest/download/menu.zip
unzip menu.zip
cd menu
cp ./* ../scripts
cd ..
rm -rf menu
rm menu.zip

echo "Getting thumbfast"
echo "======================="
#curl -O https://raw.githubusercontent.com/po5/thumbfast/vanilla-osc/player/lua/osc.lua
#curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.lua

# clamp to f1fdf10b17f394f2d42520d0e9bf22feaa20a9f4 ,because mpv subprocess create failed on Windows
curl -O https://raw.githubusercontent.com/po5/thumbfast/f1fdf10b17f394f2d42520d0e9bf22feaa20a9f4/thumbfast.lua
curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.conf
mv -f ./thumbfast.lua scripts
mv -f ./thumbfast.conf script-opts

# Change thumb size from 200px to 360px
sed -i 's/max_height=200/max_height=320/' script-opts/thumbfast.conf
sed -i 's/max_width=200/max_width=320/' script-opts/thumbfast.conf
sed -i 's/hwdec=no/hwdec=yes/' script-opts/thumbfast.conf
sed -i 's/direct_io=no/direct_io=yes/' script-opts/thumbfast.conf

echo "Getting ModernZ"
echo "============"
git clone https://github.com/Samillion/ModernZ.git --branch main
cp -f ModernZ/fluent-system-icons.ttf fonts
cp -f ModernZ/modernz.lua scripts
cp -f ModernZ/extras/pause-indicator-lite/pause_indicator_lite.lua scripts
cp -f ModernZ/modernz.conf script-opts
cp -f ModernZ/extras/locale/modernz-locale.json script-opts
rm -rf ModernZ

#Change ModernZ language from en to zh
sed -i 's/language=en/language=zh/' script-opts/modernz.conf

#echo "Getting uosc"
#echo "======================="
#git clone https://github.com/tomasklaen/uosc.git --branch main
#rm -rf fonts
#cp -r uosc/src/fonts ./
#cp -rf uosc/src/uosc scripts
#cp -f uosc/src/uosc.conf script-opts
#rm -rf uosc

# Change default languages to zh-hans.
#sed -i 's/languages=slang,en/languages=zh-hans/' script-opts/uosc.conf

# Enable autoload.
#sed -i 's/autoload=no/autoload=yes/' script-opts/uosc.conf

# Don't dim screen when menu triggered.
#sed -i 's/opacity=/opacity=curtain=0/' script-opts/uosc.conf

# Don't show timeline when paused.
#sed -i 's/timeline_persistency=paused/timeline_persistency=idle,audio/' script-opts/uosc.conf

# Change the highth of timeline to 40pixels when in fullscreen.
#sed -i 's/timeline_size_max_fullscreen=60/timeline_size_max_fullscreen=40/' script-opts/uosc.conf

# Add 'stats' 'open file' 'prev/next chapter' 'chapter' buttons.
#sed -i 's/menu,gap/menu,script-stats,open-file,gap,<has_chapter>command:skip_previous:add chapter -1?上一章节,play_pause,<has_chapter>command:skip_next:add chapter 1?下一章节,<has_chapter>chapters,gap/' script-opts/uosc.conf
#sed -i 's/<has_many_audio>audio/audio/' script-opts/uosc.conf

# Add 'play/pause' 'stats' buttons.
#sed -i "/subtitles =/i \\\t\t['play_pause'] = 'cycle:play_arrow:pause:no=pause\/yes=play_arrow?播放\/暂停'," scripts/uosc/elements/Controls.lua
#sed -i "/subtitles =/a \\\t\t['script-stats'] = 'command:analytics:script-binding stats/display-stats-toggle?统计数据'," scripts/uosc/elements/Controls.lua

echo "Getting SmartCopyPaste_II.lua"
echo "======================="
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/scripts/SmartCopyPaste_II.lua 
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/script-opts/SmartCopyPaste_II.conf 
mv -f ./SmartCopyPaste_II.lua scripts
mv -f ./SmartCopyPaste_II.conf script-opts

echo "Getting InputEvent"
echo "======================="
curl -O https://raw.githubusercontent.com/Natural-Harmonia-Gropius/InputEvent/master/inputevent.lua
mv -f ./inputevent.lua scripts

echo "Getting quality menu"
echo "======================="
curl -O https://raw.githubusercontent.com/christoph-heinrich/mpv-quality-menu/master/quality-menu.lua
mv -f ./quality-menu.lua scripts
curl -O https://raw.githubusercontent.com/christoph-heinrich/mpv-quality-menu/master/quality-menu.conf
mv -f ./quality-menu.conf script-opts

#echo "Getting autoload"
#echo "======================="
#curl -O https://raw.githubusercontent.com/mpv-player/mpv/master/TOOLS/lua/autoload.lua
#mv -f ./autoload.lua scripts

#echo "Getting mpv playlistmanager"
#echo "======================="
#curl -O https://raw.githubusercontent.com/jonniek/mpv-playlistmanager/master/playlistmanager.lua
#curl -O https://raw.githubusercontent.com/jonniek/mpv-playlistmanager/master/playlistmanager.conf
#mv -f ./playlistmanager.lua scripts
#mv -f ./playlistmanager.conf script-opts

#echo "Getting images view config"
#echo "============"
#curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/img/portable_config/scripts/img_pos.lua
#curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/img/portable_config/scripts/minimap.lua
#curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/img/portable_config/scripts/ruler.lua
#mv -f ./img_pos.lua scripts
#mv -f ./minimap.lua scripts
#mv -f ./ruler.lua scripts

echo "Getting mpv-image-config"
echo "============"
curl -O https://github.com/guidocella/mpv-image-config/blob/main/scripts/align-images.lua
curl -O https://github.com/guidocella/mpv-image-config/blob/main/scripts/image-bindings.lua
curl -O https://github.com/guidocella/mpv-image-config/blob/main/script-opts/align_images.conf
curl -O https://github.com/guidocella/mpv-image-config/blob/main/script-opts/image_bindings.conf
mv -f ./align-images.lua scripts
mv -f ./image-bindings.lua scripts
mv -f ./align_images.conf script-opts
mv -f ./image_bindings.conf script-opts

echo "Getting ytdl_hook"
echo "======================="
curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/main/portable_config/script-opts/ytdl_hook.conf
mv -f ./ytdl_hook.conf script-opts
