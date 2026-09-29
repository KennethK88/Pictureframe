local options = require "mp.options"

local opts = {
    image_duration = 20,
    display_duration = 5
}

options.read_options(opts, "location_overlay")

local current_overlay_text = nil
local file_start_time = nil
local shown = false

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function extract_overlay_text(path)
    local folder = path:match("/media/([^/]+)/")

    if folder == nil then
        folder = path:match("/cache/[^/]+/([^/]+)/")
    end

    if folder == nil then
        return nil
    end

    folder = trim(folder)

    if folder == "" then
        return nil
    end

    return folder
end

local function on_file_loaded()
    local path = mp.get_property("path")

    current_overlay_text = nil
    file_start_time = mp.get_time()
    shown = false

    if path ~= nil then
        current_overlay_text = extract_overlay_text(path)
    end

    -- Trigger a tiny OSD refresh shortly after loading a new file.
    -- On DRM/gpu output, static images can otherwise stay visually stale
    -- until the next real OSD message appears.
    mp.add_timeout(0.2, function()
        mp.osd_message(" ", 0.1)
    end)
end

local function tick()
    if current_overlay_text == nil or file_start_time == nil or shown then
        return
    end

    local duration = mp.get_property_number("duration", 0)
    local time_pos = mp.get_property_number("time-pos", 0)
    local elapsed = mp.get_time() - file_start_time

    local show_after = nil

    if duration ~= nil and duration > 0 then
        show_after = duration - opts.display_duration

        if time_pos >= show_after then
            mp.osd_message(current_overlay_text, opts.display_duration)
            shown = true
        end
    else
        show_after = opts.image_duration - opts.display_duration

        if elapsed >= show_after then
            mp.osd_message(current_overlay_text, opts.display_duration)
            shown = true
        end
    end
end

mp.register_event("file-loaded", on_file_loaded)
mp.add_periodic_timer(0.5, tick)