#!/bin/bash
set -ex

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm $DIR/macos_config/yt-dlp
rm -rf $DIR/macos_config/fonts
rm -rf $DIR/macos_config/script-opts
rm -rf $DIR/macos_config/scripts
mkdir -p $DIR/macos_config/script-opts
mkdir -p $DIR/macos_config/scripts
mkdir -p $DIR/macos_config/fonts

cd $DIR/macos_config
echo "Getting thumbfast"
echo "============"
#curl -O https://raw.githubusercontent.com/po5/thumbfast/vanilla-osc/player/lua/osc.lua
#mv -f ./osc.lua scripts

curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.lua
curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.conf
mv -f ./thumbfast.lua scripts
mv -f ./thumbfast.conf script-opts

#Change thumb size from 200px to 360px
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

echo "Getting SmartCopyPaste_II"
echo "============"
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/scripts/SmartCopyPaste_II.lua 
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/script-opts/SmartCopyPaste_II.conf 
mv -f ./SmartCopyPaste_II.lua scripts
mv -f ./SmartCopyPaste_II.conf script-opts
sed -i 's/🕒/⧗/' script-opts/SmartCopyPaste_II.conf
sed -i 's/📋/✂︎/' script-opts/SmartCopyPaste_II.conf

echo "Getting InputEvent"
echo "============"
curl -O https://raw.githubusercontent.com/Natural-Harmonia-Gropius/InputEvent/master/inputevent.lua
mv -f ./inputevent.lua scripts

echo "Getting quality menu"
echo "============"
curl -O https://raw.githubusercontent.com/christoph-heinrich/mpv-quality-menu/master/quality-menu.lua
mv -f ./quality-menu.lua scripts
curl -O https://raw.githubusercontent.com/christoph-heinrich/mpv-quality-menu/master/quality-menu.conf
mv -f ./quality-menu.conf script-opts

#echo "Getting autoload"
#echo "============"
#curl -O https://raw.githubusercontent.com/mpv-player/mpv/master/TOOLS/lua/autoload.lua
#mv -f ./autoload.lua scripts

#echo "Getting mpv playlistmanager"
#echo "============"
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
echo "============"
curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/main/portable_config/script-opts/ytdl_hook.conf
mv -f ./ytdl_hook.conf script-opts

echo "Getting yt-dlp"
echo "======================="
curl -OL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
chmod +x yt-dlp
