/* Vertical sizing for the control add-in.
 *
 * A control add-in runs in an iframe that Business Central sizes from the
 * RequestedHeight / MinimumHeight / VerticalStretch properties. That is often
 * not what you want: the frame tends to stay small no matter how much room the
 * page has. The frame is same-origin and not sandboxed, so the add-in can reach
 * its own iframe element (window.frameElement) in the host page and set the
 * height there. Three modes:
 *
 *   standard()     leave the height to Business Central (undo the other two)
 *   fill(offset)   fill the page the add-in sits on (in a FactBox: the whole
 *                  FactBox pane), less offset pixels, and follow window resizes
 *   fixed(pixels)  an exact height, set from AL
 */
window.StarterHeight = (function () {
    'use strict';

    // A "control-addin-form" shorter than this is a part (a Role Center part, a
    // FactBox), not a page worth filling; measure something bigger instead.
    const MIN_PAGE_HEIGHT = 200;
    // Height of the Role Center chrome that a part on it cannot use.
    const ROLE_CENTER_CHROME = 184;
    // Height of the FactBox pane that a part in it cannot use: the pane's header,
    // the part's caption and the padding around them.
    const FACTBOX_CHROME = 71;

    const originals = new WeakMap(); // frame -> the inline heights Business Central gave it
    let mode = 'standard';
    let fillOffset = 0;              // pixels fill mode leaves free, chosen by the caller
    let listeningOn = null;          // host window that carries our resize listener

    function getFrame() {
        try { return window.frameElement || null; } catch (_) { return null; }
    }

    function log(text) {
        if (window.console && console.debug) console.debug('[Starter AddIn] ' + text);
    }

    function setFrameHeight(frame, pixels, pinMinimum) {
        if (!originals.has(frame)) {
            originals.set(frame, {
                height: frame.style.height,
                minHeight: frame.style.minHeight,
                maxHeight: frame.style.maxHeight
            });
        }
        const value = Math.max(0, Math.round(pixels)) + 'px';
        frame.style.height = value;
        frame.style.maxHeight = value;
        // An exact height also has to win over the add-in's MinimumHeight property.
        frame.style.minHeight = pinMinimum ? value : originals.get(frame).minHeight;
    }

    /** The height the frame can take in fill mode, or null when there is nothing to measure. */
    function availableHeight(frame) {
        // A FactBox: the part is only as tall as its content, the FactBox pane is the
        // room to fill. Checked first, because a part that is already tall would
        // otherwise pass for a page and be fitted to its own height.
        const factBoxPane = frame.closest('div[class~="ms-nav-layout-factbox-pane-container"]');
        if (factBoxPane) {
            // A pane that is not displayed has no height; keep the height the frame has.
            if (!factBoxPane.offsetHeight) return null;
            return factBoxPane.offsetHeight - FACTBOX_CHROME - fillOffset;
        }
        // The page (or part) that hosts the add-in.
        const form = frame.closest('div[class~="control-addin-form"]');
        if (form && form.offsetHeight >= MIN_PAGE_HEIGHT) {
            // Whatever sits above the frame on the same page (other fields, a caption) stays visible.
            const above = Math.max(0, frame.getBoundingClientRect().top - form.getBoundingClientRect().top);
            return form.offsetHeight - above - fillOffset;
        }
        // A part on a Role Center: the part itself is small, the Role Center is the room to fill.
        const roleCenter = frame.closest('div[class~="ms-nav-layout-rolecenter"]');
        if (roleCenter) return roleCenter.offsetHeight - ROLE_CENTER_CHROME - fillOffset;
        // Anything else: from the top of the frame to the bottom of the browser window.
        const host = frame.ownerDocument.defaultView;
        return host.innerHeight - frame.getBoundingClientRect().top - fillOffset;
    }

    function fit() {
        const frame = getFrame();
        // The page was closed or the mode changed: the listener has nothing left to do.
        if (mode !== 'fill' || !frame || !frame.isConnected) { stopListening(); return; }
        try {
            const height = availableHeight(frame);
            if (height !== null) setFrameHeight(frame, height, false);
        } catch (e) {
            log('could not fit the frame: ' + e);
        }
    }

    function startListening(frame) {
        const host = frame.ownerDocument.defaultView;
        if (listeningOn === host) return;
        stopListening();
        host.addEventListener('resize', fit, true);
        listeningOn = host;
    }

    function stopListening() {
        if (!listeningOn) return;
        try { listeningOn.removeEventListener('resize', fit, true); } catch (_) { /* host window is gone */ }
        listeningOn = null;
    }

    /** Mode 1: the height Business Central gives the add-in. */
    function standard() {
        mode = 'standard';
        stopListening();
        const frame = getFrame();
        if (!frame || !originals.has(frame)) return;
        const original = originals.get(frame);
        frame.style.height = original.height;
        frame.style.minHeight = original.minHeight;
        frame.style.maxHeight = original.maxHeight;
        originals.delete(frame);
    }

    /**
     * Mode 2: fill the page, and keep filling it when the browser window is resized.
     * In a FactBox it is the whole FactBox pane that is filled.
     * Offset is the number of pixels to leave free: the margins and padding around
     * the frame that would otherwise give the page a scrollbar, or the room other
     * FactBoxes in the pane should keep. A negative offset makes the frame taller.
     */
    function fill(offset) {
        const frame = getFrame();
        if (!frame) { log('no host frame, cannot fill the parent'); return; }
        mode = 'fill';
        fillOffset = Number(offset) || 0;
        startListening(frame);
        fit();
        // Once more when the page has finished its own layout.
        frame.ownerDocument.defaultView.requestAnimationFrame(fit);
    }

    /** Mode 3: an exact height in pixels. */
    function fixed(pixels) {
        const frame = getFrame();
        if (!frame) { log('no host frame, cannot set the height'); return; }
        mode = 'fixed';
        stopListening();
        setFrameHeight(frame, Number(pixels) || 0, true);
    }

    return { standard, fill, fixed };
})();
