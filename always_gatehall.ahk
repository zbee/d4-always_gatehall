; Written by zbee (Ethan Henderson)
; https://github.com/zbee
; 2024-02-01, Season 3

; https://github.com/zbee/d4-always_gatehall


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Core keybinds, from the game's settings
global map_keybind := "{M}"  ; Controls > Menus > Map Screen
#HotIf WinActive("Diablo IV")
    g::open_map()            ; Controls > Gameplay > Town Portal
#HotIf

; Adjust these as needed for your system
global very_short_sleep := 50 ; After zooms and map drags
global short_sleep := 175     ; Next to clicks and keybinds
global medium_sleep := 250    ; After making UI changes, such as opening filters
global long_sleep := 350      ; After opening screens, like the map

; Colors searched for, and their tolerances
; Could need adjusted based on brightness
; top middle red of the close button, in the top right of your map
global screen_close_button_red := 0xEA4F31
global screen_close_button_tolerance := 10

; The first "deep" blue above the triangle in the center of a waypoint icon
global waypoint_blue := 0x26CDDE
global waypoint_tolerance := 10

; The x coordinate of the map area buttons, the 2nd pixel from the left
; This is fallback functionality for maps without "1", "2", etc icons,
; and almost certainly won't work for you without customization, see below
global map_area_depth := 62

; There are more colors in the _get_to_world_map() function
; However, these colors are only used if the map areas section of your map does
; not have the number icons, ie when in a special area like Gatehall,
; so they should not matter
; Additonally, if you find you need to update these colors: you will likely also
; need to update the images next to this program

; Filter keybind, which is displayed on your map, when on the overworld map
global filter_keybind := "{F}" ; Keybind not adjustable in game


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
; Open the user's map, reset it to the world map, zoom out, and reposition it
; until the gatehall is found, then restore map filters, and teleport to the
; gatehall
;
open_map() {
    if (WinActive("Diablo IV")) {
        ; Exit if chat is open
        if (_chat_open()) {
            return
        }

        ; Open the map
        _open_map()

        ; Close the journal if open
        _close_journal()

        ; Set the map to the world map, zoom it out
        _set_map()

        ; Disable waypoint map filter
        filter_location := _set_filters()

        ; Search for the gatehall
        gatehall_location := _search_for_gatehall()

        ; Restore the map filters
        _restore_filters(filter_location)
        
        ; Click the gatehall if found
        if (gatehall_location[1] > -1 && gatehall_location[2] > -1) {
            debug(
                _Click_gatehall(gatehall_location[1], gatehall_location[2])
                ? "Teleporting to gatehall"
                : "Could not teleport to gatehall"
            )
        }
    }
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Core Functionality
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
; Whether the chat is open
;
_chat_open() {
    all_channels_button_found := ImageSearch(
        &found_x, &found_y,
        A_ScreenWidth/4*3, A_ScreenHeight/2,
        A_ScreenWidth, A_ScreenHeight,
        "*30 *TransBlack all_chat_channels.png"
    )
    debug("all channels found: " . all_channels_button_found)
    debug(found_x . ", " . found_y)
    
    expand_chat_button_found := ImageSearch(
        &found_x, &found_y,
        A_ScreenWidth/5*4, A_ScreenHeight/2,
        A_ScreenWidth, A_ScreenHeight,
        "*30 *TransBlack expand_chat.png"
    )
    debug("expand found: " . expand_chat_button_found)
    debug(found_x . ", " . found_y)
    debug("Chat open: " . (all_channels_button_found || expand_chat_button_found))

    chat_open := all_channels_button_found || expand_chat_button_found

    if (chat_open) {
        debug("Chat open, aborting ...")
    }

    return chat_open
}


;
; Open the user's map
;
_open_map() {
    ; Send the map keybind and wait
    debug("Opening Map...")
    Send(map_keybind)
    Sleep(long_sleep)

    ; The position of the close button
    position_of_map_close_x := A_ScreenWidth - 34
    position_of_map_close_y := 25

    ; Search for the close button color with 6px on the X, and 2px on the Y,
    ; with a tolerance of 10 in color difference (4 more than largest observed)
    close_button_color_found := PixelSearch(
        &color_x, &color_y,
        position_of_map_close_x - 3, position_of_map_close_y - 1,
        position_of_map_close_x + 3, position_of_map_close_y + 1,
        screen_close_button_red, screen_close_button_tolerance
    )

    ; If we actually just closed the map, reopen it
    if (!close_button_color_found) {
        debug("...Reopening Map")
        Send(map_keybind)
        Sleep(medium_sleep)
    }
}

;
; Close the journal if it is open
;
_close_journal() {
    ; Check for the journal
    journal_open := ImageSearch(
        &found_x, &found_y,
        A_ScreenWidth/2, A_ScreenHeight/3,
        A_ScreenWidth, A_ScreenHeight,
        "*60 open_journal.png"
    )

    ; Close the journal if open
    if (journal_open) {
        debug("Closing journal ...")
        Click(found_x + 5, found_y + 5)
        Sleep(medium_sleep)
    } else {
        debug("Journal already closed ...")
    }
}

;
; Click the highest map area that is not your current area, ie Sanctuary,
; ie the overworld
;
_get_to_world_map() {
    ; Search for the "1", "2", etc icons that are shown in the list of areas
    map_area_labels_found := ImageSearch(
        &found_x, &found_y,
        0, A_ScreenHeight/3,
        150, A_ScreenHeight,
        "*30 world_area_section.png"
    )
    ; If the labels were found, work off of this instead of checking colors
    if (map_area_labels_found) {
        ; Click 70px below the found area
        ; This location should be the "Sanctuary" area under the "2" icon next
        ; to "World Map"
        found_y := found_y + 70

        debug("Clicking to overworld map, via label icon, at coordinates: " . found_x . ", " . found_y)
        Click(found_x, found_y)
        Sleep(medium_sleep)
        return
    }

    ; Legacy functionality below
    ; This functionality should only run if in a special area, such as Gatehall

    ;
    ; colors of map area options that are not selected
    ; these colors have no tolerance!
    notSelected_map_colors := [
        "0x1F221F",
        "0x26221F",
        "0x26251F",
        "0x26241F",
        "0x26221F",
        "0x23221F",
        "0x1F221F",
        "0x292521",
        "0x201C1A",
        "0x1D1817",
        "0x23201C",
        "0x1E1D1A",
        "0x1A1D1A",
        "0x1E1D1A",
        "0x201D1A",
        "0x201F1A",
        "0x20201A",
        "0x1B1D1A",
        "0x111411"
    ]
    ; these colors come from the pixels along the vertical axis of the 2nd pixel
    ; from the left of unselected zones when multiple zones are shown
    ; eg, when in a dungeon, screenshot, look at the Sanctuary entry
    ;

    ; the vertical position of the map area buttons
    y := A_ScreenHeight - 134

    ; variables to conrol the search for the top map area button
    found_not_current_map_zone := false
    counted := 0
    counted_after_last_found := 0
    counted_in_color := 0
    y_coordinate := 0

    ; iterate over every pixel from near the bottom left of the screen,
    ; vertically, looking for pixels that match the color of map areas that
    ; are not your current area (i.e. Sanctuary)
    ;
    ; once pixels that are that color are found, it keeps searching for more,
    ; up until 55 not-correct pixels are found; this way it can support finding
    ; Sanctuary even if your dungeon/etc has several map areas
    ;
    ; finally, last-y-coordinate-of-matching is only if 10 other colors were
    ; also found; this prevents coincedental color matches from causing a Click
    while (y >= 0 && counted < 100 && counted_after_last_found < 55) {
        color := PixelGetColor(map_area_depth, y)
        colorString := Format("0x{:06X}", color)

        if (_arr_contains(notSelected_map_colors, colorString)) {
            found_not_current_map_zone := true
            counted_in_color++

            if (counted_in_color > 10) {
                y_coordinate := y
            }
        }
        else {
            if (found_not_current_map_zone = true) {
                counted_after_last_found++
            }
        }

        y--
        y--
        y--
        counted++
    }

    if y_coordinate > 0 {
        debug("Clicking to overworld map, at coordinates: " . map_area_depth . ", " . y_coordinate)
        Click(map_area_depth, y_coordinate)
        Sleep(medium_sleep)
    }
    else {
        debug("...Could not find overworld map area, assuming on overworld")
    }
}

;
; Zoom out the map, open the map filters, and reposition to find the gatehall
;
_set_map() {
    ; Get to the world map, unless filters are open
    ; (filter only opens on world map)
    if (!ImageSearch(
        &trash, &trasht,
        50, A_ScreenHeight/3,
        600, A_ScreenHeight,
        "*90 filter_design.png"
    )) {
        _get_to_world_map()
    } else {
        debug("Already on world map, as filters are open")
    }

    ; Zoom out the map
    Send "{WheelDown 2}"
    Sleep(very_short_sleep)
    Send "{WheelDown 2}"
    Sleep(short_sleep)
}

;
; Disable waypoint map filter, returning the position to then restore
;
_set_filters() {
    ; Open the map filters
    debug("Opening map filters ...")
    Send(filter_keybind)
    Sleep(short_sleep)

    ; Check for the waypoint filter
    waypoints_on := ImageSearch(
        &found_x, &found_y,
        50, A_ScreenHeight/2,
        600, A_ScreenHeight,
        "*60 waypoint_filter.png"
    )
    
    ; Disable the waypoint filter if on
    if (waypoints_on) {
        debug("Disabling waypoint filter, at coordinates: " . found_x . ", " . found_y . " ...")
        Click(found_x, found_y)
        Sleep(medium_sleep)
        
        ; Close filter menu
        Send(filter_keybind)
        Sleep(long_sleep)
    } else {
        debug("Waypoint filter already disabled ... cannot restore")
        found_x := -1
        found_y := -1
    }

    ; Return the position of the filter button for restoration
    return [found_x, found_y]
}

;
; Search for the position of the gatehall
;
_find_gatehall() {
    Sleep(short_sleep)

    ; Search for the gatehall
    if (PixelSearch(
        &color_x, &color_y,
        0, 0,
        A_ScreenWidth, A_ScreenHeight,
        waypoint_blue, waypoint_tolerance
    )) {
        debug("...Found gatehall")
        return [color_x, color_y]
    }
    else {
        debug("Could not find gatehall ...")
    }
    return [-1, -1]
}

;
; Scroll map to find the gatehall
;
_search_for_gatehall() {
    ; Search for the gatehall; if it can't be found, drag the map around
    dragged_bottom_left := false
    dragged_bottom_left_fully := false

    found_gatehall := _found_gatehall()
    attempts := 0

    debug("Searching for gatehall ...")

    while (!found_gatehall && attempts < 10) {
        ; Break if the user holds escape
        if (GetKeyState("Esc"))
        {
            break
        }
        ; Break if the active window is no longer Diablo IV
        if (!WinActive("Diablo IV"))
        {
            break
        }
        ; Break if the chat is open
        if (_chat_open())
        {
            break
        }
    
        debug("...Repositioning map ...")

        ; Drag it to the bottom left
        if (!dragged_bottom_left) {
            MouseClickDrag(
                "left",
                10, A_ScreenHeight-200,
                A_ScreenWidth-10, 200
            )
            Sleep(very_short_sleep)
            MouseClickDrag(
                "left",
                10, A_ScreenHeight-200,
                A_ScreenWidth-10, 200
            )
            Sleep(very_short_sleep)
            MouseClickDrag(
                "left",
                10, A_ScreenHeight-200,
                A_ScreenWidth-10, 200
            )
            dragged_bottom_left := true
            Sleep(short_sleep)
        }

        ; Start dragging it back to the top right, little by little
        if (dragged_bottom_left) {
            Send "{WheelDown}"
            Sleep(very_short_sleep)
            MouseClickDrag(
                "left",
                A_ScreenWidth-500, 350,
                A_ScreenWidth-1100, 900
            )
            Sleep(short_sleep)
        }

        ; Search again
        found_gatehall := _found_gatehall()
        attempts++
    }

    return _find_gatehall()
}

;
; Restore the waypoint map filter with the given position
;
_restore_filters(filter_location) {
    ; Open the map filters
    Send(filter_keybind)
    Sleep(short_sleep)

    ; Restore the waypoint filter
    debug("Restoring waypoint filter ...")
    Click(filter_location[1], filter_location[2])
    Sleep(short_sleep)

    ; Close filter menu
    Send(filter_keybind)
    Sleep(short_sleep)
}

;
; Click the gatehall on the map if found, otherwise return false
;
_Click_gatehall(x, y, attempt_number := 0) {
    debug("...Clicking gatehall, at coordinates: " . x . ", " . y . " ...")

    ; Click the gatehall
    Sleep(short_sleep)
    Click(x, y)
    Sleep(long_sleep)

    ; Check for the confirmation window, to prevent accidentally typing
    confirmation_open := ImageSearch(
        &found_x, &found_y,
        A_ScreenWidth/3, A_ScreenHeight/3,
        A_ScreenWidth/3*2, A_ScreenHeight/3*2,
        "*50 teleport_confirmation.png"
    )

    ;Only press enter if the confirmation is open
    if (confirmation_open) {
        Send "{Enter}"
        return true
    }
    else {
        if (attempt_number > 1) {
            debug("...Could not find confirmation window")
            return false
        }

        debug("...Could not find confirmation window, trying again ...")
        return _Click_gatehall(x, y, attempt_number + 1)
    }
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
; Helper function to output a message to the debug console
;
debug(message) {
    OutputDebug(message)        
}

;
; Whether _find_gatehall() returns a positive result
;
_found_gatehall() {
    find_result := _find_gatehall()
    return find_result[1] > -1 && find_result[2] > -1
}

;
; Helper function to check for value in array
;
_arr_contains(arr, val) {
    for each, item in arr {
        if (item = val) {
            return true
        }
    }
    return false
}
