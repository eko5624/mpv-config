--[[

快捷指令增强

input.conf 示例：

 Ctrl+a               script-binding input_plus/adevice_back        # 上一个音频输出设备
#                     script-binding input_plus/adevice_next        # 下...
#                     script-binding input_plus/adevice_all_back    # 上...（包括不属于当前 --ao 的设备）
#                     script-binding input_plus/adevice_all_next    # 下...

#                     script-binding input_plus/info_toggle         # 仿Pot的OSD启用/禁用常驻显示简要信息

 Ctrl+v               script-binding input_plus/load_cbd            # 加载剪贴板地址
#                     script-binding input_plus/load_cbd_add        # ...（追加到列表）
#                     script-binding input_plus/load_cbd_alt        # 加载主缓冲区地址（仅Linux可用）
#                     script-binding input_plus/load_cbd_alt_add    # ...（追加到列表）

#                     script-binding input_plus/mark_aid_A          # 标记当前音轨为A
#                     script-binding input_plus/mark_aid_B          # 标记当前音轨为B
#                     script-binding input_plus/mark_aid_merge      # 合并AB音轨
#                     script-binding input_plus/mark_aid_reset      # 取消AB并轨和标记
 m                    script-binding input_plus/mark_aid_fin        # （单键实现上述四项命令）

 Alt+p                script-binding input_plus/playlist_order_0    # 播放列表的洗牌与撤销
#                     script-binding input_plus/playlist_order_0r   # ...（重定向至首个文件）
#                     script-binding input_plus/playlist_order_1    # 播放列表连续洗牌（可用上两项命令恢复）
#                     script-binding input_plus/playlist_order_1r   # ...
#                     script-binding input_plus/playlist_tmp_save   # 保存当前播放列表为临时列表（位于主设置目录 playlist_temp.mpl ）
#                     script-binding input_plus/playlist_tmp_load   # 打开临时播放列表

 CLOSE_WIN            script-binding input_plus/quit_real           # 对执行退出命令前的确认（防止误触）
#                     script-binding input_plus/quit_wait           # 延后退出命令的执行（执行前再次触发可取消）

#                     script-binding input_plus/seek_auto_back      # [可持续触发] 后退至上句字幕的时间点或上一关键帧
#                     script-binding input_plus/seek_auto_next      # [可持续触发] 前进至下...
#                     script-binding input_plus/seek_skip_back      # 向后大跳（精确帧）
#                     script-binding input_plus/seek_skip_next      # 向前...

 SPACE                script-binding input_plus/speed_auto          # [按住/松开] 两倍速/一倍速
#                     script-binding input_plus/speed_auto_bullet   # [按住/松开] 子弹时间/一倍速
#                     script-binding input_plus/speed_recover       # 仿Pot的速度重置与恢复

#                     script-binding input_plus/stats_1_2           # 单键浏览统计数据第1至2页
#                     script-binding input_plus/stats_0_4           # 单键浏览统计数据第0至4页

#                     script-binding input_plus/trackA_back         # 上一个音频轨道（自动跳过无轨道）
#                     script-binding input_plus/trackA_next         # 下...
#                     script-binding input_plus/trackS_back         # 上一个字幕轨道...
#                     script-binding input_plus/trackS_next         # 下...
#                     script-binding input_plus/trackV_back         # 上一个视频轨道...
#                     script-binding input_plus/trackV_next         # 下...

#                     script-binding input_plus/x264_cmpt           # 开/关 旧版x264即时兼容模式

--]]


local utils = require("mp.utils")

--
-- 函数设定
--


local adevicelist = {}
function adevicelist_update(start, fin, step, dynamic)
	local target_ao = nil
	if dynamic then
		target_ao = ""
	else
		target_ao = mp.get_property_native("current-ao", "")
	end
	while start ~= fin + step do
		if string.find(mp.get_property_native("audio-device"), adevicelist[start].name, 1, true) then
			while true do
				if start + step == 0 then
					start = #adevicelist + 1
				elseif start + step == #adevicelist + 1 then
					start = 0
				end
				start = start + step
				if string.find(adevicelist[start].name, target_ao, 1, true) then
					mp.set_property("audio-device", adevicelist[start].name)
					adevicelist[start].description = "■ " .. adevicelist[start].description
					local adevice_content = tostring("音频输出设备：\n")
					for items = 1, #adevicelist do
						if string.find(adevicelist[items].name, target_ao, 1, true) then
							if adevicelist[items].name ~= adevicelist[start].name then
								adevice_content = adevice_content .. "□ "
							end
							adevice_content = adevice_content .. adevicelist[items].description .. "\n"
						end
					end
					mp.osd_message(adevice_content, 2)
					return
				end
			end
		end
		start = start + step
	end
end

local osm = mp.create_osd_overlay("ass-events")
local osm_showing = false
local style_generic = "{\\rDefault\\fnConsolas\\fs28\\blur1\\bord2\\3c&H000000}"
function info_get()
	local osd_dims = mp.get_property_native("osd-dimensions")
	local w_s, h_s = osd_dims["w"] - osd_dims["ml"] - osd_dims["mr"], osd_dims["h"] - osd_dims["mt"] - osd_dims["mb"]
	local cur_name = mp.get_property_osd("media-title") or mp.get_property_osd("filename")
	local vid_params = mp.get_property_native("video-dec-params") or "..."
	local w_raw, h_raw, pix_fmt, color_lv = vid_params["w"] or 0, vid_params["h"] or 0, vid_params["hw-pixelformat"] or vid_params["pixelformat"] or "...", vid_params["colorlevels"] or "..."
	local bitrateV, bitrateA = mp.get_property_number("video-bitrate", 0) / 1000, mp.get_property_number("audio-bitrate", 0) / 1000
	local txt = (
	style_generic.."输出尺寸： ".."{\\1c&H0099FF}".."["..w_s.."] x ["..h_s.."]".."\n"..
	style_generic.."解码模式： ".."{\\1c&H0099FF}"..mp.get_property_native("hwdec-current", "...").."\n"..
	style_generic.."显示同步： ".."{\\1c&H0099FF}"..mp.get_property_native("video-sync", "...").."\n"..
	style_generic.."丢帧：     ".."{\\1c&H0099FF}"..mp.get_property_number("frame-drop-count", 0).."\n"..
	style_generic.."文件：     ".."{\\1c&H0099FF}"..cur_name:gsub("\\n", " "):gsub("\\$", ""):gsub("{","\\{").."\n"..
	style_generic.."视频 ┓".."\n"..
	style_generic.."____输出： ".."{\\1c&H03A89E}"..mp.get_property_native("current-vo", "...").."\n"..
	style_generic.."____编码： ".."{\\1c&H03A89E}"..mp.get_property_native("video-codec", "...").."\n"..
	style_generic.."____尺寸： ".."{\\1c&H03A89E}".."["..w_raw.."] x ["..h_raw.."]".."\n"..
	style_generic.."____像素： ".."{\\1c&H03A89E}"..pix_fmt.."\n"..
	style_generic.."____动态： ".."{\\1c&H03A89E}"..color_lv.."\n"..
	style_generic.."____帧率： ".."{\\1c&H03A89E}"..mp.get_property_number("container-fps", 0).." FPS（原始） "..
		                                            mp.get_property_number("estimated-vf-fps", 0).." FPS（目标）".."\n"..
	style_generic.."____码率： ".."{\\1c&H03A89E}"..bitrateV.." kbps".."\n"..
	style_generic.."音频 ┓".."\n"..
	style_generic.."____输出： ".."{\\1c&H9EA803}"..mp.get_property_native("current-ao", "...").."\n"..
	style_generic.."____设备： ".."{\\1c&H9EA803}"..mp.get_property_native("audio-device", "...").."\n"..
	style_generic.."____编码： ".."{\\1c&H9EA803}"..mp.get_property_native("audio-codec", "...").."\n"..
	style_generic.."____码率： ".."{\\1c&H9EA803}"..bitrateA.." kbps"
	)
	return tostring(txt)
end
function info_toggle()
	if osm_showing then
		osm:remove()
		osm_timer:kill()
		osm_showing = false
		return
	end
	osm.data = info_get()
	osm:update()
	osm_showing = true
	osm_timer = mp.add_periodic_timer(0.5, function()
		if not osm_showing then
			osm_timer:kill()
		else
			osm.data = info_get()
			osm:update()
		end
	end)
end

function check_plat()
	if os.getenv("windir") ~= nil then
		return "windows"
	elseif string.sub((os.getenv("HOME")), 1, 6) == "/Users" then
		return "macos"
	elseif os.getenv("WAYLAND_DISPLAY") then
		return "wayland"
	end
	return "x11"
end
local plat = check_plat()
function copy_clipboard(clip)
	if plat == "windows" then
		local res = utils.subprocess({
			args = { 'powershell', '-NoProfile', '-Command', [[& {
				Trap {
					Write-Error -ErrorRecord $_
					Exit 1
				}
				$clip = ""
				if (Get-Command "Get-Clipboard" -errorAction SilentlyContinue) {
					$clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
				} else {
					Add-Type -AssemblyName PresentationCore
					$clip = [Windows.Clipboard]::GetText()
				}
				$clip = $clip -Replace "`r",""
				$u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
				[Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
			}]] },
			playback_only = false,
		})
		if not res.error then
			return res.stdout
		end
	elseif plat == "macos" then
		local res = utils.subprocess({args = { 'pbpaste' }, playback_only = false,})
		if not res.error then
			return res.stdout
		end
	elseif plat == "x11" then
		local res = utils.subprocess({args = { 'xclip', '-selection', clip and 'clipboard' or 'primary', '-out' }, playback_only = false,})
		if not res.error then
			return res.stdout
		end
	elseif plat == "wayland" then
		local res = utils.subprocess({args = { 'wl-paste', clip and '-n' or  '-np' }, playback_only = false,})
		if not res.error then
			return res.stdout
		end
	end
	return ""
end
local text_pasted = nil
function load_clipboard(clip, action)
	local text = copy_clipboard(clip):gsub("^%s*", ""):gsub("%s*$", "")
	if text == text_pasted and action == "replace" then
		mp.osd_message("剪贴板内容无变动", 1)
		return
	end
	mp.commandv("loadfile", text, action)
	text_pasted = text
end

local marked_aid_A = nil
local marked_aid_B = nil
local merged_aid = false
function mark_aid_A()
	marked_aid_A = mp.get_property_number("aid", 0)
	if marked_aid_A == 0
	then
		mp.osd_message("当前音轨无效", 1)
		marked_aid_A = nil
	else
		mp.osd_message("预标记当前音轨序列 " .. marked_aid_A .. " 为并行轨A", 1)
	end
end
function mark_aid_B()
	marked_aid_B = mp.get_property_number("aid", 0)
	if marked_aid_B == 0
	then
		mp.osd_message("当前音轨无效", 1)
		marked_aid_B = nil
	else
		mp.osd_message("预标记当前音轨序列 " .. marked_aid_B .. " 为并行轨B", 1)
	end
end
function mark_aid_merge()
	if marked_aid_A == marked_aid_B or marked_aid_A == nil or marked_aid_B == nil
	then
		mp.osd_message("无效的AB音轨", 1)
		marked_aid_A, marked_aid_B = nil, nil
	else
		mp.command("set lavfi-complex \"[aid" .. marked_aid_A .. "] [aid" .. marked_aid_B .. "] amix [ao]\"")
		mp.osd_message("已合并AB音轨", 1)
		merged_aid = true
	end
end
function mark_aid_reset()
	mp.command("set lavfi-complex \"\"")
	merged_aid = false
	marked_aid_A, marked_aid_B = nil, nil
end
function mark_aid_fin()
	if merged_aid then
		mark_aid_reset()
		mp.osd_message("已取消并轨和标记", 1)
		mp.commandv("set", "aid", "auto")
		return
	end
	if marked_aid_A == nil then
		mark_aid_A()
		return
	end
	if marked_aid_B == nil then
		mark_aid_B()
		return
	end
	mark_aid_merge()
end

local shuffled = false
local shuffling = false
local save_path = mp.command_native({"expand-path", "~~/"}) .. "/playlist_temp.mpl"
function show_playlist_shuffle()
	mp.add_timeout(0.1, function()
		local shuffle_msg = mp.command_native({"expand-text", "${playlist}"})
		shuffling = false
		mp.osd_message(shuffle_msg, 2)
	end)
end
function playlist_order(mode, re)
	if shuffling then
		mp.msg.info("已阻止高频洗牌")
		return
	end
	if mp.get_property_number("playlist-count") <= 2 then
		mp.osd_message("播放列表中的条目数量不足", 1)
		return
	end
	shuffling = true
	if mode == 0 then
		if not shuffled then
			mp.command("playlist-shuffle")
			shuffled = true
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist_shuffle()
		else
			mp.command("playlist-unshuffle")
			shuffled = false
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist_shuffle()
		end
	elseif mode == 1 then
		if shuffled then
			mp.command("playlist-unshuffle")
			mp.command("playlist-shuffle")
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist_shuffle()
		else
			mp.command("playlist-shuffle")
			shuffled = true
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist_shuffle()
		end
	end
end
function playlist_tmp_save()
	local item_num = mp.get_property_number("playlist-count", 0)
	if item_num == 0 then
		mp.osd_message("播放列表中无文件", 1)
		return
	end
	local file, err = io.open(save_path, "w")
	file:write("#EXTM3U\n\n")
	local Nn = 0
	while Nn < item_num do
		local save_item = mp.get_property("playlist/"..Nn.."/filename")
		file:write(save_item, "\n")
		Nn = Nn+1
	end
	local save_info = tostring("已保存至临时播放列表")
	mp.osd_message(save_info, 1)
	mp.msg.info("playlist_tmp_save 主设置文件夹/playlist_temp.mpl")
	file:close()
end
function playlist_tmp_load()
	mp.commandv("loadlist", save_path, "replace")
	if mp.get_property_number("playlist-count", 0) == 0 then
		mp.osd_message("临时播放列表加载失败", 1)
	else
		mp.osd_message(mp.command_native({"expand-text", "${playlist}"}), 2)
	end
end

local pre_quit = false
function quit_real()
	if pre_quit then
		mp.command("quit")
	else
		mp.osd_message("再次执行以确认退出", 1)
		pre_quit = true
		mp.add_timeout(1, function()
			pre_quit = false
			mp.msg.verbose("quit_real 检测到误触退出键")
		end)
	end
end
function quit_wait()
	if pre_quit then
		pre_quit = false
		return
	else
		pre_quit = true
		mp.osd_message("即将退出，再次执行以取消", 3)
		mp.add_timeout(3, function()
			if pre_quit then
				mp.command("quit")
			else
				mp.osd_message("已取消退出", 0.5)
				return
			end
		end)
	end
end

function seek_auto(num)
	local current_sid = mp.get_property_number("sid", 0)
	if current_sid == 0 then
		mp.command("seek " .. 0.1 * num .. " keyframes")
	else
		mp.command("sub-seek " .. num .. " primary")
	end
end
function seek_skip(num)
	local duration_div_chapters = mp.get_property_number("duration", 1) / mp.get_property_number("chapter-list/count", 1)
	if duration_div_chapters >= 240 then
		mp.command("seek " .. 10 * num .. " relative-percent+exact")
	elseif duration_div_chapters == 1 then
		mp.command("seek " .. 60 * num .. " exact")
	else
		mp.commandv("add", "chapter", num)
		mp.command("show-progress")
	end
end

local bak_speed = nil
function speed_auto(tab)
	if tab.event == "down" then
		mp.set_property_number("speed", 2)
		mp.msg.verbose("speed_auto 加速播放中")
	elseif tab.event == "up" then
		mp.set_property_number("speed", 1)
		mp.msg.verbose("speed_auto 已恢复常速")
	end
end
function speed_auto_bullet(tab)
	if tab.event == "down" then
		mp.set_property_number("speed", 0.5)
		mp.msg.verbose("speed_auto_bullet 子弹时间中")
	elseif tab.event == "up" then
		mp.set_property_number("speed", 1)
		mp.msg.verbose("speed_auto_bullet 已恢复常速")
	end
end
function speed_recover()
	if mp.get_property_number("speed") ~= 1 then
		bak_speed = mp.get_property_number("speed")
		mp.command("set speed 1")
	else
		if bak_speed == nil then
			bak_speed = 1
		end
		mp.command("set speed " .. bak_speed)
	end
end

local show_page = 0
function stats_cycle(num_init, num_end)
	if show_page < num_init then
		show_page = num_init - 1
	end
	if show_page >= num_end then
		show_page = num_init - 1
	end
	show_page = show_page + 1
	mp.command("script-binding stats/display-page-" .. show_page)
end

function track_seek(id, num)
	mp.command("add " .. id .. " " .. num)
	if mp.get_property_number(id, 0) == 0 then
		mp.command("add " .. id .. " " .. num)
		if mp.get_property_number(id, 0) == 0 then
			mp.osd_message("无可用轨道", 1)
		end
	end
end

local temp_avc = false
local x264_cmpt_warn = tostring("x264_cmpt 可能破坏常规h264文件的播放")
function x264_cmpt()
	local current_vid = mp.get_property_number("vid", 0)
	if current_vid == 0 then
		mp.osd_message("当前视频轨道无效", 1)
		return
	end
	if temp_avc then
		mp.set_property_bool("vd-lavc-assume-old-x264", false)
		temp_avc = false
		mp.osd_message("已禁用旧版x264即时兼容模式", 1)
		mp.set_property_number("vid", 0)
		mp.set_property_number("vid", current_vid)
		return
	end
	mp.set_property_bool("vd-lavc-assume-old-x264", true)
	temp_avc = true
	mp.osd_message("已启用旧版x264即时兼容模式", 1)
	mp.msg.warn(x264_cmpt_warn)
	mp.set_property_number("vid", 0)
	mp.set_property_number("vid", current_vid)
end


--
-- 事件注册
--


mp.register_event("end-file", function() if marked_aid_A ~= nil or marked_aid_B ~= nil then mark_aid_reset() end end)

--mp.register_event("end-file", function() if temp_avc then mp.set_property_bool("vd-lavc-assume-old-x264", false) temp_avc = false end end)
mp.register_event("start-file", function() if temp_avc then mp.msg.warn(x264_cmpt_warn) end end)


--
-- 键位绑定
--


mp.add_key_binding(nil, "adevice_back", function() adevicelist = mp.get_property_native("audio-device-list") adevicelist_update(#adevicelist, 1, -1) end)
mp.add_key_binding(nil, "adevice_next", function() adevicelist = mp.get_property_native("audio-device-list") adevicelist_update(1, #adevicelist, 1) end)
mp.add_key_binding(nil, "adevice_all_back", function() adevicelist = mp.get_property_native("audio-device-list") adevicelist_update(#adevicelist, 1, -1, true) end)
mp.add_key_binding(nil, "adevice_all_next", function() adevicelist = mp.get_property_native("audio-device-list") adevicelist_update(1, #adevicelist, 1, true) end)

mp.add_key_binding(nil, "info_toggle", info_toggle)

mp.add_key_binding(nil, "load_cbd", function() load_clipboard(true, "replace") end)
mp.add_key_binding(nil, "load_cbd_alt", function() load_clipboard(false, "replace") end)
mp.add_key_binding(nil, "load_cbd_add", function() load_clipboard(true, "append-play") end)
mp.add_key_binding(nil, "load_cbd_alt_add", function() load_clipboard(false, "append-play") end)

mp.add_key_binding(nil, "mark_aid_A", mark_aid_A)
mp.add_key_binding(nil, "mark_aid_B", mark_aid_B)
mp.add_key_binding(nil, "mark_aid_merge", mark_aid_merge)
mp.add_key_binding(nil, "mark_aid_reset", function() mark_aid_reset() mp.osd_message("已取消并轨和标记", 1) end)
mp.add_key_binding(nil, "mark_aid_fin", mark_aid_fin)

mp.add_key_binding(nil, "playlist_order_0", function() playlist_order(0) end)
mp.add_key_binding(nil, "playlist_order_0r", function() playlist_order(0, true) end)
mp.add_key_binding(nil, "playlist_order_1", function() playlist_order(1) end)
mp.add_key_binding(nil, "playlist_order_1r", function() playlist_order(1, true) end)
mp.add_key_binding(nil, "playlist_tmp_save", playlist_tmp_save)
mp.add_key_binding(nil, "playlist_tmp_load", playlist_tmp_load)

mp.add_key_binding(nil, "quit_real", quit_real)
mp.add_key_binding(nil, "quit_wait", quit_wait)

mp.add_key_binding(nil, "seek_auto_back", function() seek_auto(-1) end, {repeatable = true})
mp.add_key_binding(nil, "seek_auto_next", function() seek_auto(1) end, {repeatable = true})
mp.add_key_binding(nil, "seek_skip_back", function() seek_skip(-1) end)
mp.add_key_binding(nil, "seek_skip_next", function() seek_skip(1) end)

mp.add_key_binding(nil, "speed_auto", speed_auto, {complex = true})
mp.add_key_binding(nil, "speed_auto_bullet", speed_auto_bullet, {complex = true})
mp.add_key_binding(nil, "speed_recover", speed_recover)

mp.add_key_binding(nil, "stats_1_2", function() stats_cycle(1, 2) end)
mp.add_key_binding(nil, "stats_0_4", function() stats_cycle(0, 4) end)

mp.add_key_binding(nil, "trackA_back", function() track_seek("aid", -1) end)
mp.add_key_binding(nil, "trackA_next", function() track_seek("aid", 1) end)
mp.add_key_binding(nil, "trackS_back", function() track_seek("sid", -1) end)
mp.add_key_binding(nil, "trackS_next", function() track_seek("sid", 1) end)
mp.add_key_binding(nil, "trackV_back", function() track_seek("vid", -1) end)
mp.add_key_binding(nil, "trackV_next", function() track_seek("vid", 1) end)

mp.add_key_binding(nil, "x264_cmpt", x264_cmpt)
