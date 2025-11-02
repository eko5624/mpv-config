#!/bin/bash
shopt -s extglob
set -ex

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm $DIR/linux_config/yt-dlp
mkdir -p $DIR/linux_config/script-opts
mkdir -p $DIR/linux_config/scripts

cd $DIR/linux_config
echo "Getting thumbfast"
echo "============"
curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.lua
curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.conf
mv -f ./thumbfast.lua scripts
mv -f ./thumbfast.conf script-opts

#Change thumb size from 200px to 360px
sed -i 's/max_height=200/max_height=320/' script-opts/thumbfast.conf
sed -i 's/max_width=200/max_width=320/' script-opts/thumbfast.conf
sed -i 's/hwdec=no/hwdec=yes/' script-opts/thumbfast.conf
sed -i 's/direct_io=no/direct_io=yes/' script-opts/thumbfast.conf

echo "Getting uosc"
echo "============"
git clone https://github.com/tomasklaen/uosc.git --branch main
cp -r uosc/src/fonts ./
cp -rf uosc/src/uosc scripts
cp -f uosc/src/uosc.conf script-opts
rm -rf uosc

# Change default languages to zh-hans.
sed -i 's/languages=slang,en/languages=zh-hans/' script-opts/uosc.conf

# Enable autoload.
sed -i 's/autoload=no/autoload=yes/' script-opts/uosc.conf

# Don't dim screen when menu triggered.
sed -i 's/opacity=/opacity=curtain=0/' script-opts/uosc.conf

# Don't show timeline when paused.
sed -i 's/timeline_persistency=paused/timeline_persistency=idle,audio/' script-opts/uosc.conf

# Change the highth of timeline to 40pixels when in fullscreen.
sed -i 's/timeline_size_max_fullscreen=60/timeline_size_max_fullscreen=40/' script-opts/uosc.conf

# Add 'stats' 'open file' 'prev/next chapter' 'chapter' buttons.
sed -i 's/menu,gap/menu,script-stats,open-file,gap,<has_chapter>command:skip_previous:add chapter -1?上一章节,play_pause,<has_chapter>command:skip_next:add chapter 1?下一章节,<has_chapter>chapters,gap/' script-opts/uosc.conf
sed -i 's/<has_many_audio>audio/audio/' script-opts/uosc.conf

# Add 'play/pause' 'stats' buttons.
sed -i "/subtitles =/i \\\t\t['play_pause'] = 'cycle:play_arrow:pause:no=pause\/yes=play_arrow?播放\/暂停'," scripts/uosc/elements/Controls.lua
sed -i "/subtitles =/a \\\t\t['script-stats'] = 'command:analytics:script-binding stats/display-stats-toggle?统计数据'," scripts/uosc/elements/Controls.lua

#echo "Getting ModernZ"
#echo "============"
#git clone https://github.com/Samillion/ModernZ.git --branch main
#cp -f ModernZ/fluent-system-icons.ttf fonts
#cp -f ModernZ/modernz.lua scripts
#cp -f ModernZ/extras/pause-indicator-lite/pause_indicator_lite.lua scripts
#cp -f ModernZ/modernz.conf script-opts
#cp -f ModernZ/extras/locale/modernz-locale.json script-opts
#rm -rf ModernZ

#Change ModernZ language from en to zh
#sed -i 's/language=en/language=zh/' script-opts/modernz.conf

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

echo "Getting yt-dlp"
echo "======================="
curl -OL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
chmod +x yt-dlp
