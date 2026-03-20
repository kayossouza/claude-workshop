#!/usr/bin/env osascript -l JavaScript

ObjC.import('AppKit');

function run() {
    var allScreens = $.NSScreen.screens;
    var count = allScreens.count;

    if (count === 0) {
        return JSON.stringify([]);
    }

    // Main screen is always index 0 in NSScreen.screens
    var mainFrame = allScreens.objectAtIndex(0).frame;
    var mainScreenHeight = mainFrame.size.height;

    var screens = [];

    for (var i = 0; i < count; i++) {
        var screen = allScreens.objectAtIndex(i);
        var frame = screen.visibleFrame;
        var isMain = (i === 0);

        var nsX = frame.origin.x;
        var nsY = frame.origin.y;
        var w = frame.size.width;
        var h = frame.size.height;

        // Convert from Cocoa coordinates (bottom-left origin, y up)
        // to AppleScript coordinates (top-left of main screen origin, y down)
        var appleY = mainScreenHeight - nsY - h;
        var appleX = nsX;

        var area = w * h;

        screens.push({
            index: i,
            isMain: isMain,
            x: Math.round(appleX),
            y: Math.round(appleY),
            w: Math.round(w),
            h: Math.round(h),
            area: Math.round(area)
        });
    }

    // Sort by area descending (largest first)
    screens.sort(function(a, b) { return b.area - a.area; });

    // Re-index after sorting
    for (var j = 0; j < screens.length; j++) {
        screens[j].index = j;
    }

    return JSON.stringify(screens, null, 2);
}
