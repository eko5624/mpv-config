#!/bin/bash
shopt -s extglob
set -ex

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

rm -rf $DIR/portable_config/scripts/!("info_ontop.lua")
mkdir -p $DIR/portable_config/script-opts
mkdir -p $DIR/portable_config/scripts

cd $DIR/portable_config

#echo "Getting HDR Toys"
#echo "======================="
#curl -OL https://github.com/natural-harmonia-gropius/hdr-toys/archive/refs/heads/master.zip
#unzip master.zip
#cd "hdr-toys-master"
#cp -f scripts/hdr-toys.lua ../scripts
#cp -f hdr-toys.conf ../
#cp -rf shaders ../
#cd ..
#rm -rf "hdr-toys-master"
#rm master.zip

#echo "Getting thumbfast"
#echo "======================="
# clamp to f1fdf10b17f394f2d42520d0e9bf22feaa20a9f4 ,because mpv subprocess create failed on Windows
#curl -O https://raw.githubusercontent.com/po5/thumbfast/f1fdf10b17f394f2d42520d0e9bf22feaa20a9f4/thumbfast.lua
#curl -O https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.conf
#mv -f ./thumbfast.lua scripts
#mv -f ./thumbfast.conf script-opts

# Change thumb size from 200px to 360px
#sed -i 's/max_height=200/max_height=320/' script-opts/thumbfast.conf
#sed -i 's/max_width=200/max_width=320/' script-opts/thumbfast.conf
#sed -i 's/hwdec=no/hwdec=yes/' script-opts/thumbfast.conf
#sed -i 's/direct_io=no/direct_io=yes/' script-opts/thumbfast.conf

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
