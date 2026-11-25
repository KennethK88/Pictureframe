--[[
    Pictureframe – Location Overlay

    Displays location information during media playback using mpv's OSD.

    Extracts location information from the media file's directory name
    and displays it shortly before the current media finishes.

    Supports configurable image and overlay display durations.
    Location information is displayed only once per media file.
]]

local options = require "mp.options"

local opts = {
    image_duration = 20,
    display_duration = 5
}

options.read_options(opts, "location_overlay")

local current_overlay_text = nil
local file_start_time = nil
local shown = false

-- Removes leading and trailing whitespace from a string.
local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

-- Extracts location information from a media or cache file path.
-- Normalizes directory names by removing the month from date prefixes
-- while preserving the year and location information.
-- Returns nil if no valid location information can be extracted.
local function extract_overlay_text(path)
    local folder = path:match("/media/([^/]+)/")

    if folder == nil then
        folder = path:match("/cache/[^/]+/([^/]+)/")
    end

    if folder == nil then
        return nil
    end

    folder = folder:gsub("^(%d%d%d%d)%-%d%d%s+", "%1 ")
    folder = trim(folder)

    if folder == "" then
        return nil
    end

    return folder
end

-- Initializes the overlay state when a new media file is loaded.
-- Extracts the location text and triggers a small OSD refresh
-- to prevent stale image rendering on DRM/GPU output.
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

-- Periodically checks whether the location overlay should be displayed.
-- Shows the overlay shortly before the media finishes.
-- Uses the configured image duration if no media duration is available.
-- Ensures that the overlay is displayed only once per media file.
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

-- Register the media loading event and periodic overlay timer.
mp.register_event("file-loaded", on_file_loaded)
mp.add_periodic_timer(0.5, tick)