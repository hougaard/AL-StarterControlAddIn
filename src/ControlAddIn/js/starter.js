/* The add-in itself: content and captions from AL, and messages back to AL.
 *
 * Every procedure on the controladdin object in AL calls a global JavaScript
 * function with the same name. They are defined at the bottom of this file.
 */
window.StarterAddIn = (function () {
    'use strict';

    const FLAG = '__starterAddInStarted';
    const CAPTION_ATTRIBUTE = 'data-caption';

    let captions = null; // key -> text, sent from AL labels with SetCaptions

    /** The element Business Central gives every control add-in to draw in. */
    function root() {
        return document.getElementById('controlAddIn');
    }

    /* ---- Captions --------------------------------------------------------
     * No text a user reads is written in the add-in. AL holds every text as a
     * Label (so it is translated with the rest of the app) and sends the set as
     * one JSON object. The HTML only names the caption it wants:
     *
     *   <h2 data-caption="heading"></h2>                       the element's text
     *   <input data-caption-placeholder="searchHint">          any attribute
     *   <button data-caption="save" data-caption-title="saveTip"></button>
     */

    /**
     * The text for a caption key. Extra arguments fill %1..%9, as in AL labels:
     * caption('rowCount', 12) with "Rows: %1" gives "Rows: 12". A key AL did not
     * send comes back as the key itself, so a missing caption is easy to spot.
     */
    function caption(key) {
        const text = captions && typeof captions[key] === 'string' ? captions[key] : '';
        if (text === '') return String(key);
        const values = arguments;
        return text.replace(/%([1-9])/g, (placeholder, number) => {
            return values[number] !== undefined ? String(values[number]) : placeholder;
        });
    }

    /** Fills every element that names a caption. Setting an element's text replaces its children. */
    function applyCaptions() {
        if (!captions) return; // nothing sent yet: leave the page as it was written
        root().querySelectorAll('*').forEach(element => {
            Array.from(element.attributes).forEach(attribute => {
                if (attribute.name === CAPTION_ATTRIBUTE) {
                    element.textContent = caption(attribute.value);
                } else if (attribute.name.indexOf(CAPTION_ATTRIBUTE + '-') === 0) {
                    element.setAttribute(attribute.name.slice(CAPTION_ATTRIBUTE.length + 1), caption(attribute.value));
                }
            });
        });
    }

    /** Adds captions to the set (the same key again replaces the text) and repaints the page. */
    function setCaptions(values) {
        captions = Object.assign(captions || {}, values || {});
        applyCaptions();
    }

    /* ---- Content --------------------------------------------------------- */

    /**
     * Replaces the add-in's content with an HTML page. A whole document works:
     * <style> and <link rel="stylesheet"> from its head are kept, the body becomes
     * the content, and its scripts run. That is the point, and also the risk: pass
     * only HTML you trust (your own resources), never text a user typed.
     */
    function setHtml(html) {
        const page = new DOMParser().parseFromString(String(html || ''), 'text/html');
        const content = document.createDocumentFragment();
        page.querySelectorAll('head style, head link[rel="stylesheet"], head script').forEach(node => {
            content.appendChild(document.importNode(node, true));
        });
        Array.from(page.body.childNodes).forEach(node => {
            content.appendChild(document.importNode(node, true));
        });
        // A parsed script never runs; a script element created here does.
        content.querySelectorAll('script').forEach(parsed => {
            const script = document.createElement('script');
            Array.from(parsed.attributes).forEach(attribute => script.setAttribute(attribute.name, attribute.value));
            script.text = parsed.text;
            script.async = false; // keep the order they have in the page
            parsed.replaceWith(script);
        });
        root().replaceChildren(content);
        applyCaptions();
    }

    /**
     * Shows an image in the element with the given id. Source is anything an
     * <img> accepts; from AL it is a data URI built from an app resource.
     */
    function setImage(elementId, source) {
        const element = document.getElementById(elementId);
        if (!element) {
            console.warn('[Starter AddIn] SetImage: no element with id "' + elementId + '"');
            return;
        }
        if (element.tagName === 'IMG') element.src = source;
        else element.style.backgroundImage = 'url("' + source + '")';
    }

    /* ---- Messages to AL -------------------------------------------------- */

    /** Raises the OnMessage event in AL. Data is any JSON object. */
    function send(name, data) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnMessage', [String(name), data || {}], false);
    }

    /**
     * Any element with a data-message attribute raises OnMessage when clicked,
     * with its other data-* attributes (captions aside) as the data:
     *   <button data-message="height-fixed" data-pixels="600"></button>
     * raises OnMessage('height-fixed', {"pixels": "600"}).
     */
    function onClick(e) {
        const element = e.target && e.target.closest ? e.target.closest('[data-message]') : null;
        if (!element) return;
        const data = {};
        Object.keys(element.dataset).forEach(key => {
            if (key !== 'message' && key.indexOf('caption') !== 0) data[key] = element.dataset[key];
        });
        send(element.dataset.message, data);
    }

    /** Called by the startup script. Safe to call again when the control is recreated. */
    function start() {
        if (window.StarterKeyForwarder) window.StarterKeyForwarder.install();
        if (window[FLAG]) return;
        window[FLAG] = true;
        document.addEventListener('click', onClick);
    }

    return { start, setCaptions, caption, setHtml, setImage, send };
})();

/* The procedures of the controladdin object. */
window.SetCaptions = captions => window.StarterAddIn.setCaptions(captions);
window.SetHtml = html => window.StarterAddIn.setHtml(html);
window.SetImage = (elementId, source) => window.StarterAddIn.setImage(elementId, source);
window.UseStandardHeight = () => window.StarterHeight.standard();
window.FillParent = offset => window.StarterHeight.fill(offset);
window.SetHeight = pixels => window.StarterHeight.fixed(pixels);
