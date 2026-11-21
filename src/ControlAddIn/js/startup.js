/* Startup and recreate: runs when the add-in has loaded, and again if Business
 * Central recreates the control. AL answers OnControlReady by sending the
 * content and choosing the height, so both cases end up in the same state.
 */
(function () {
    'use strict';
    window.StarterAddIn.start();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnControlReady', [], false);
})();
