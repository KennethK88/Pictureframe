local options = require "mp.options"

local opts = {
    image_duration = 30,
    display_duration = 5
}

options.read_options(opts, "location_overlay")

local current_location = nil
local file_start_time = nil
local shown = false

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function extract_location(path)
    local folder = path:match("/media/([^/]+)/")

    if folder == nil then
        folder = path:match("/cache/optimized/([^/]+)/")
    end

    if folder == nil then
        return nil
    end

    folder = folder:gsub("^%d%d%d%d%-%d%d%s+", "")
    folder = folder:gsub("^%d%d%d%d%s+", "")
    folder = trim(folder)

    if folder == "" then
        return nil
    end

    return folder
end

local function on_file_loaded()
    local path = mp.get_property("path")

    current_location = nil
    file_start_time = mp.get_time()
    shown = false

    if path ~= nil then
        current_location = extract_location(path)
    end

    mp.osd_message("", 0)
end

local function tick()
    if current_location == nil or file_start_time == nil or shown then
        return
    end

    local duration = mp.get_property_number("duration", 0)
    local time_pos = mp.get_property_number("time-pos", 0)
    local elapsed = mp.get_time() - file_start_time

    local show_after = nil

    if duration ~= nil and duration > 0 then
        show_after = duration - opts.display_duration

        if time_pos >= show_after then
            mp.osd_message(current_location, opts.display_duration)
            shown = true
        end
    else
        show_after = opts.image_duration - opts.display_duration

        if elapsed >= show_after then
            mp.osd_message(current_location, opts.display_duration)
            shown = true
        end
    end
end

mp.register_event("file-loaded", on_file_loaded)
mp.add_periodic_timer(0.5, tick)