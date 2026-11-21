/* Business Central shortcut forwarding for the control add-in.
 *
 * A control add-in runs in an iframe. Keyboard events never cross the frame
 * boundary, so a Business Central shortcut (Alt+Q, Alt+T, F5, Escape, ...)
 * pressed while focus is inside the add-in is lost: the web client's keydown
 * listeners in the host document never see it.
 *
 * This listener catches such keys in the capture phase and re-dispatches a copy
 * of the keydown on the iframe element itself (window.frameElement) in the host
 * document, where it bubbles through the same ancestors a real keypress on the
 * page would. The add-in iframe is same-origin and not sandboxed, so this works.
 *
 * The web client matches its shortcuts on event.which / event.keyCode (not on
 * event.key) and type-guards with "instanceof KeyboardEvent", so the copy is
 * built with the host window's constructor and carries which/keyCode. Pure JS,
 * no AL round trip. install() is idempotent, so a control recreation is safe.
 */
window.StarterKeyForwarder = (function () {
    'use strict';

    const FLAG = '__starterKeyForwarderInstalled';

    // The web client's own check is "ctrlKey === isMacOS": on Windows/Linux the
    // shortcuts are Alt+<key> and Ctrl+Alt is AltGr (types characters such as @
    // on many layouts), on macOS the shortcuts are Ctrl+Option+<key>.
    const IS_MAC = /Mac|iPhone|iPad|iPod/.test((navigator.platform || '') + ' ' + (navigator.userAgent || ''));

    /**
     * Decides whether a keydown is a Business Central shortcut rather than a key
     * the add-in itself may use. Returns:
     *   'now'            forward immediately and swallow the original
     *                    (function keys, Alt + letter/digit)
     *   'unlessHandled'  forward after the add-in's own handlers have run, and only
     *                    if none of them called preventDefault (Escape closes the
     *                    page in BC, but may also close a popup or an editor in the
     *                    add-in; never forwarded from a field, where it would throw
     *                    the user's work away)
     *   null             not a BC shortcut, leave it alone
     *
     * If your add-in uses function keys or Alt combinations itself, return null
     * for those here.
     */
    function classify(e) {
        const key = e.key || '';
        const code = e.code || '';
        if (key === 'Alt' || key === 'Control' || key === 'Shift' || key === 'Meta' || key === 'AltGraph') return null;
        if (/^F([1-9]|1[0-2])$/.test(key)) return 'now';
        if (key === 'Escape' && !e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey) {
            // A native <dialog> closes itself on Escape without any handler calling
            // preventDefault; that Escape is the dialog's, not the page's.
            if (document.querySelector('dialog[open]')) return null;
            // Escape in a field (clearing a search box, leaving an edit) must never
            // close the whole Business Central page and the work on it.
            if (isEditable(e.target)) return null;
            return 'unlessHandled';
        }
        if (e.altKey && !e.metaKey && e.ctrlKey === IS_MAC) {
            if (/^(Key[A-Z]|Digit[0-9])$/.test(code) || /^[a-z0-9]$/i.test(key)) return 'now';
        }
        return null;
    }

    /** An input, textarea, select or contenteditable element, or something inside one. */
    function isEditable(target) {
        if (!target || target.nodeType !== 1) return false;
        if (target.isContentEditable) return true;
        return !!(target.closest && target.closest('input, textarea, select, [contenteditable]:not([contenteditable="false"])'));
    }

    function defineIfDifferent(target, name, value) {
        if (target[name] === value) return;
        try {
            Object.defineProperty(target, name, { value, enumerable: true, configurable: true });
        } catch (_) { /* not configurable in this browser; the init dictionary value stands */ }
    }

    /** Dispatches a copy of the keydown on the iframe element in the host page. True when it reached the host. */
    function forward(e) {
        try {
            const frame = window.frameElement;
            if (!frame || !frame.ownerDocument) return false;
            // Each frame has its own KeyboardEvent class and the web client checks
            // "instanceof KeyboardEvent"; an event made in this frame fails that.
            const hostWindow = frame.ownerDocument.defaultView || window.parent;
            const Ctor = (hostWindow && hostWindow.KeyboardEvent) || KeyboardEvent;
            const copy = new Ctor('keydown', {
                key: e.key,
                code: e.code,
                location: e.location,
                repeat: e.repeat,
                keyCode: e.keyCode,
                which: e.which,
                altKey: e.altKey,
                ctrlKey: e.ctrlKey,
                shiftKey: e.shiftKey,
                metaKey: e.metaKey,
                bubbles: true,
                cancelable: true,
                composed: true
            });
            // Some browsers ignore the legacy keyCode/which members of the init
            // dictionary; the web client reads them, so make sure they are there.
            defineIfDifferent(copy, 'keyCode', e.keyCode);
            defineIfDifferent(copy, 'which', e.which);
            frame.dispatchEvent(copy);
            return true;
        } catch (_) {
            return false; // cross-origin parent or dispatch failure
        }
    }

    function log(key, sent) {
        if (window.console && console.debug) {
            console.debug('[Starter AddIn] ' + (sent ? 'forwarded ' + key + ' to host page' : 'could not forward ' + key + ' (no host frame)'));
        }
    }

    function onKeyDown(e) {
        const mode = classify(e);
        if (!mode) return;
        if (mode === 'now') {
            e.preventDefault();
            e.stopPropagation();
            log(e.key, forward(e));
            return;
        }
        // 'unlessHandled': let the event finish its normal dispatch inside the
        // add-in first. Dispatch is synchronous, so by the time this timer runs
        // defaultPrevented tells whether the add-in used the key.
        setTimeout(() => {
            if (e.defaultPrevented) return;
            log(e.key, forward(e));
        }, 0);
    }

    function install() {
        try {
            if (window[FLAG]) return;
            window[FLAG] = true;
            window.addEventListener('keydown', onKeyDown, true);
        } catch (_) { /* never let this break the add-in */ }
    }

    return { install };
})();
