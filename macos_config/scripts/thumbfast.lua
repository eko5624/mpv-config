--[[
SOURCE_ https://github.com/po5/thumbfast/commit/eb21b2e871144a328f93c4597cc1932b43783e6a

适配多个OSC类脚本的新缩略图引擎
]]--

local options = {

    socket = "",           -- Socket path (leave empty for auto)
    tnpath = "",           -- 缩略图缓存路径（确保目录真实存在），留空即自动

    max_height = 300,      -- Maximum thumbnail size in pixels (scaled down to fit) Values are scaled when hidpi is enabled
    max_width = 300,
    max_thumbs = 1440,     -- 最大缩略图数量

    overlay_id = 42,       -- Overlay id

    spawn_first = false,   -- Spawn thumbnailer on file load for faster initial thumbnails
    network = false,       -- Enable on network playback
    audio = false,         -- Enable on audio playback

    min_duration = 0,      -- 对短视频关闭预览（秒）
    precise = true,        -- 启用高精度的预览
    hwdec = true,          -- 启用硬解加速
    frequency = 0.2,       -- 解码频率（秒）

}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options)

local os_name = ""

math.randomseed(os.time())
local unique = math.random(10000000)
local init = false

local spawned = false
local network = false
local disabled = false
local interval = 0

local x = nil
local y = nil
local last_x = x
local last_y = y

local last_seek_time = nil

local effective_w = options.max_width
local effective_h = options.max_height
local real_w = nil
local real_h = nil

local script_name = nil

local show_thumbnail = false

local file_timer = nil
local file_check_period = 1/60
local first_file = false

local seek_flag = "absolute"
if options.precise then seek_flag = seek_flag.."+exact" else seek_flag = seek_flag.."+keyframes" end

local function get_os()
    local raw_os_name = ""

    if jit and jit.os and jit.arch then
        raw_os_name = jit.os
    else
        if package.config:sub(1,1) == "\\" then
            -- Windows
            local env_OS = os.getenv("OS")
            if env_OS then
                raw_os_name = env_OS
            end
        else
            raw_os_name = mp.command_native({name = "subprocess", playback_only = false, capture_stdout = true, args = {"uname", "-s"}}).stdout
        end
    end

    raw_os_name = (raw_os_name):lower()

    local os_patterns = {
        ["windows"] = "Windows",

        -- Uses socat
        ["linux"]   = "Linux",

        ["osx"]     = "Mac",
        ["mac"]     = "Mac",
        ["darwin"]  = "Mac",

        ["^mingw"]  = "Windows",
        ["^cygwin"] = "Windows",

        -- Because they have the good netcat (with -U)
        ["bsd$"]    = "Mac",
        ["sunos"]   = "Mac"
    }

    -- Default to linux
    local str_os_name = "Linux"

    for pattern, name in pairs(os_patterns) do
        if raw_os_name:match(pattern) then
            str_os_name = name
            break
        end
    end

    return str_os_name
end

local function calc_dimensions()
    local width = mp.get_property_number("video-out-params/dw")
    local height = mp.get_property_number("video-out-params/dh")
    if not width or not height then return end

    local scale = mp.get_property_number("display-hidpi-scale", 1)

    if width / height > options.max_width / options.max_height then
        effective_w = math.floor(options.max_width * scale + 0.5)
        effective_h = math.floor(height / width * effective_w + 0.5)
    else
        effective_h = math.floor(options.max_height * scale + 0.5)
        effective_w = math.floor(width / height * effective_h + 0.5)
    end
end

local function info(w, h)
    local display_w, display_h = w, h

    local json, err = mp.utils.format_json({width=display_w, height=display_h, disabled=disabled, socket=options.socket, tnpath=options.tnpath, overlay_id=options.overlay_id})
    mp.commandv("script-message", "thumbfast-info", json)
end

local function remove_thumbnail_files()
    os.remove(options.tnpath)
    os.remove(options.tnpath..".bgra")
end

local function spawn(time)
    if disabled then return end

    local path = mp.get_property("path")
    if path == nil then return end

    spawned = true

    local open_filename = mp.get_property("stream-open-filename")
    local ytdl = open_filename and network and path ~= open_filename
    if ytdl then
        path = open_filename
    end

    if os_name == "" then
        os_name = get_os()
    end

    if options.socket == "" then
        if os_name == "Windows" then
            options.socket = "thumbfast"
        elseif os_name == "Mac" then
            options.socket = "/tmp/thumbfast"
        else
            options.socket = "/tmp/thumbfast"
        end
    end

    if options.tnpath == "" then
        if os_name == "Windows" then
            options.tnpath = os.getenv("TEMP").."\\thumbfast.out"
        elseif os_name == "Mac" then
            options.tnpath = "/tmp/thumbfast.out"
        else
            options.tnpath = "/tmp/thumbfast.out"
        end
    end

    if not init then
        -- ensure uniqueness
        options.socket = options.socket .. unique
        options.tnpath = options.tnpath .. unique
        init = true
    end

    remove_thumbnail_files()

    local mpv_hwdec = "no"
    if options.hwdec then mpv_hwdec = "auto" end
    mp.command_native_async(
        {name = "subprocess", playback_only = true, args = {
            "mpv", path, "--config=no", "--terminal=no", "--msg-level=all=no", "--idle=yes", "--keep-open=always","--pause=yes", "--ao=null", "--vo=null",
            "--load-auto-profiles=no", "--load-osd-console=no", "--load-stats-overlay=no", "--osc=no",
            "--vd-lavc-skiploopfilter=all", "--vd-lavc-skipidct=all", "--vd-lavc-software-fallback=1", "--vd-lavc-fast", "--vd-lavc-threads=2", "--hwdec="..mpv_hwdec,
            "--edition="..(mp.get_property_number("edition") or "auto"), "--vid="..(mp.get_property_number("vid") or "auto"), "--sub=no", "--audio=no", "--sub-auto=no", "--audio-file-auto=no",
            "--input-ipc-server="..options.socket,
            "--start="..time,
            "--ytdl-format=worst", "--demuxer-readahead-secs=0", "--demuxer-max-bytes=128KiB",
            "--gpu-dumb-mode=yes", "--tone-mapping=clip", "--hdr-compute-peak=no",
            "--sws-scaler=point", "--sws-fast=yes", "--sws-allow-zimg=no",
            "--audio-pitch-correction=no",
            "--vf=".."scale=w="..effective_w..":h="..effective_h..":flags=neighbor,format=bgra",
            "--ovc=rawvideo", "--of=image2", "--ofopts=update=1", "--ocopy-metadata=no", "--o="..options.tnpath
        }},
        function() end
    )
end

local function run(command, callback)
    if not spawned then return end

    callback = callback or function() end

    local seek_command
    if os_name == "Windows" then
        seek_command = {"cmd", "/c", "echo "..command.." > \\\\.\\pipe\\" .. options.socket}
    elseif os_name == "Mac" then
        -- this doesn't work, on my system. not sure why.
        seek_command = {"/usr/bin/env", "sh", "-c", "echo '"..command.."' | nc -w0 -U " .. options.socket}
    else
        seek_command = {"/usr/bin/env", "sh", "-c", "echo '" .. command .. "' | socat - " .. options.socket}
    end

    mp.command_native_async(
        {name = "subprocess", playback_only = true, capture_stdout = true, args = seek_command},
        callback
    )
end

local function thumb_index(thumbtime)
    return math.floor(thumbtime / interval)
end

local function index_time(index, thumbtime)
    if interval > 0 then
        local time = index * interval
        return time + interval / 3
    else
        return thumbtime
    end
end

local function draw(w, h, script)
    if not w or not show_thumbnail then return end
    local display_w, display_h = w, h

    if x ~= nil then
        mp.command_native(
            {name = "overlay-add", id=options.overlay_id, x=x, y=y, file=options.tnpath..".bgra", offset=0, fmt="bgra", w=display_w, h=display_h, stride=(4*display_w)}
        )
    elseif script then
        local json, err = mp.utils.format_json({width=display_w, height=display_h, x=x, y=y, socket=options.socket, tnpath=options.tnpath, overlay_id=options.overlay_id})
        mp.commandv("script-message-to", script, "thumbfast-render", json)
    end
end

local function real_res(req_w, req_h, filesize)
    local count = filesize / 4
    local diff = (req_w * req_h) - count

    if diff == 0 then
        return req_w, req_h
    else
        local threshold = 5 -- throw out results that change too much
        local long_side, short_side = req_w, req_h
        if req_h > req_w then
            long_side, short_side = req_h, req_w
        end
        for a = short_side, short_side - threshold, -1 do
            if count % a == 0 then
                local b = count / a
                if long_side - b < threshold then
                    if req_h < req_w then return b, a else return a, b end
                end
            end
        end
        return nil
    end
end

local function move_file(from, to)
    if os_name == "Windows" then
        os.remove(to)
    end
    -- move the file because it can get overwritten while overlay-add is reading it, and crash the player
    os.rename(from, to)
end

local last_seek = 0
local function seek()
    if last_seek_time then
        last_seek = mp.get_time()
        run("async seek " .. last_seek_time .. " " .. seek_flag)
    end
end

local seek_period = options.frequency
local seek_timer = mp.add_timeout(seek_period, seek)
seek_timer:kill()
local function request_seek()
    if seek_timer:is_enabled() then return end
    local next_seek = seek_period - (mp.get_time() - last_seek)
    if next_seek <= 0 then seek() return end
    seek_timer.timeout = next_seek
    seek_timer:resume()
end

local function check_new_thumb()
    local finfo = mp.utils.file_info(options.tnpath)
    if not finfo then return false end

    -- the slave might start writing to the file after checking existance and
    -- validity but before actually moving the file, so move to a temporary
    -- location before validity check to make sure everything stays consistant
    -- and valid thumbnails don't get overwritten by invalid ones
    local tmp = options.tnpath..".tmp"
    move_file(options.tnpath, tmp)
    if first_file then
        request_seek()
        first_file = false
    end
    finfo = mp.utils.file_info(tmp)
    if not finfo then return false end
    local w, h = real_res(effective_w, effective_h, finfo.size)
    if w then -- only accept valid thumbnails
        move_file(tmp, options.tnpath..".bgra")

        real_w, real_h = w, h
        if real_w then info(real_w, real_h) end
        return true
    end
    return false
end

file_timer = mp.add_periodic_timer(file_check_period, function()
    if check_new_thumb() then
        draw(real_w, real_h, script_name)
    end
end)
file_timer:kill()

local function thumb(time, r_x, r_y, script)
    if disabled then return end

    time = tonumber(time)
    if time == nil then return end

    if r_x == nil or r_y == nil then
        x, y = nil, nil
    else
        x, y = math.floor(r_x + 0.5), math.floor(r_y + 0.5)
    end

    local index = thumb_index(time)
    local seek_time = index_time(index, time)

    script_name = script
    if last_x ~= x or last_y ~= y or seek_time ~= last_seek_time or not show_thumbnail then
        show_thumbnail = true
        last_x = x
        last_y = y
        draw(real_w, real_h, script)
    end

    if seek_time == last_seek_time then return end
    last_seek_time = seek_time
    if not spawned then spawn(seek_time) end
    request_seek()
    if not file_timer:is_enabled() then file_timer:resume() end
end

local function clear()
    file_timer:kill()
    seek_timer:kill()
    last_seek = 0
    show_thumbnail = false
    last_x = nil
    last_y = nil
    mp.command_native(
        {name = "overlay-remove", id=options.overlay_id}
    )
end

local function watch_changes()
    local old_w = effective_w
    local old_h = effective_h

    calc_dimensions()

    if spawned then
        if old_w ~= effective_w or old_h ~= effective_h then
            -- mpv doesn't allow us to change output size
            run("quit")
            clear()
            info(effective_w, effective_h)
            spawned = false
            spawn(last_seek_time or mp.get_property_number("time-pos", 0))
        end
    else
        if old_w ~= effective_w or old_h ~= effective_h then
            info(effective_w, effective_h)
        end
    end
end

local function sync_changes(prop, val)
    if spawned and val then
        run("set "..prop.." "..val)
    end
end

local function file_load()
    clear()
    real_w, real_h = nil, nil
    last_seek_time = nil

    network = mp.get_property_bool("demuxer-via-network", false)
    local image = mp.get_property_native("current-tracks/video/image", true)
    local albumart = image and mp.get_property_native("current-tracks/video/albumart", false)
    local short_video = mp.get_property_native("duration", 0) <= options.min_duration

    disabled = (network and not options.network) or (albumart and not options.audio) or (image and not albumart) or (short_video and options.min_duration > 0)
    calc_dimensions()
    info(effective_w, effective_h)
    if disabled then return end

    interval = math.min(math.max(mp.get_property_number("duration", 1) / options.max_thumbs, 0), mp.get_property_number("duration", 0) / 2)

    spawned = false
    if options.spawn_first then
        spawn(mp.get_property_number("time-pos", 0))
        first_file = true
    end
end

local function shutdown()
    run("quit")
    remove_thumbnail_files()
    os.remove(options.socket)
end

mp.observe_property("display-hidpi-scale", "native", watch_changes)
mp.observe_property("video-out-params", "native", watch_changes)
mp.observe_property("vid", "native", sync_changes)
mp.observe_property("edition", "native", sync_changes)

mp.register_script_message("thumb", thumb)
mp.register_script_message("clear", clear)

mp.register_event("file-loaded", file_load)
mp.register_event("shutdown", shutdown)
