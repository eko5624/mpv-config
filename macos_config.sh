#!/bin/bash
set -ex

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -rf $DIR/macos_config/fonts
rm -rf $DIR/macos_config/script-opts
rm -rf $DIR/macos_config/scripts
mkdir -p $DIR/macos_config/script-opts
mkdir -p $DIR/macos_config/scripts

cd $DIR/macos_config 
# get thumbfast
git clone https://github.com/po5/thumbfast.git --branch master
cp -f thumbfast/thumbfast.lua scripts  
cp -f thumbfast/thumbfast.conf script-opts
rm -rf thumbfast

#Change thumb size from 200px to 360px
sed -i 's/max_height=200/max_height=360/' script-opts/thumbfast.conf
sed -i 's/max_width=200/max_width=360/' script-opts/thumbfast.conf
sed -i 's/hwdec=no/hwdec=yes/' script-opts/thumbfast.conf
sed -i 's/direct_io=no/direct_io=yes/' script-opts/thumbfast.conf

# get uosc
git clone https://github.com/tomasklaen/uosc.git --branch main
cp -r uosc/fonts ./
cp -rf uosc/scripts/* scripts
cp -f uosc/script-opts/uosc.conf script-opts
rm -rf uosc

# Don't dim screen when menu triggered.
sed -i 's/curtain_opacity=0.5/curtain_opacity=0/' script-opts/uosc.conf

# Don't show timeline when paused.
sed -i 's/timeline_persistency=paused/timeline_persistency=idle,audio/' script-opts/uosc.conf

# Change the highth of timeline to 40pixels when in fullscreen.
sed -i 's/timeline_size_max_fullscreen=60/timeline_size_max_fullscreen=40/' script-opts/uosc.conf

# Add 'stats' 'open file' 'prev/next chapter' 'chapter' buttons.
sed -i 's/menu,gap/menu,script-stats,open-file,gap,<has_chapter>command:skip_previous:add chapter -1?上一章节,play_pause,<has_chapter>command:skip_next:add chapter 1?下一章节,<has_chapter>chapters,gap/' script-opts/uosc.conf
sed -i 's/<has_many_audio>audio/audio/' script-opts/uosc.conf

# Add simplified chinese translation.
sed -i "/subtitles =/i \\\t\t['play_pause'] = 'cycle:play_arrow:pause:no=pause\/yes=play_arrow?播放\/暂停'," scripts/uosc_shared/elements/Controls.lua
sed -i "/subtitles =/a \\\t\t['script-stats'] = 'command:analytics:script-binding stats/display-stats-toggle?统计数据'," scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Menu/?菜单/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Subtitles/?字幕轨/' scripts/uosc_shared/elements/Controls.lua
sed -i "s/?Audio',/?音频轨',/" scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Audio device/?音频设备/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Video/?视频轨/' scripts/uosc_shared/elements/Controls.lua
sed -i "s/?Playlist',/?播放列表',/" scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Chapters/?章节/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Editions/?版本/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Stream quality/?流品质/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Open file/?加载文件/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Playlist\/Files/?播放列表\/文件浏览器/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Previous/?上一个/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Next/?下一个/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?First/?首位/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Last/?末位/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Loop playlist/?列表循环/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Loop file/?单曲循环/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Shuffle/?乱序播放/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Fullscreen/?切换全屏/' scripts/uosc_shared/elements/Controls.lua

# Get SmartCopyPaste_II.lua
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/scripts/SmartCopyPaste_II.lua 
curl -O https://raw.githubusercontent.com/Eisa01/mpv-scripts/master/script-opts/SmartCopyPaste_II.conf 
mv -f ./SmartCopyPaste_II.lua scripts
mv -f ./SmartCopyPaste_II.conf script-opts
sed -i 's/🕒/⧗/' script-opts/SmartCopyPaste_II.conf
sed -i 's/📋/✂︎/' script-opts/SmartCopyPaste_II.conf

# Get InputEvent.lua
curl -O https://raw.githubusercontent.com/Natural-Harmonia-Gropius/InputEvent/master/inputevent.lua
mv -f ./inputevent.lua scripts

# Get autoload.lua
curl -O https://raw.githubusercontent.com/mpv-player/mpv/master/TOOLS/lua/autoload.lua
mv -f ./autoload.lua scripts

# Get mpv-playlistmanager
curl -O https://raw.githubusercontent.com/jonniek/mpv-playlistmanager/master/playlistmanager.lua
curl -O https://raw.githubusercontent.com/jonniek/mpv-playlistmanager/master/playlistmanager.conf
mv -f ./playlistmanager.lua scripts
mv -f ./playlistmanager.conf script-opts

# Get stats.conf
curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/main/portable_config/script-opts/stats.conf
mv -f ./stats.conf script-opts

# Get ytdl_hook.conf
curl -O https://raw.githubusercontent.com/hooke007/MPV_lazy/main/portable_config/script-opts/ytdl_hook.conf
mv -f ./ytdl_hook.conf script-opts
