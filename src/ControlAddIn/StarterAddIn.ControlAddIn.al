namespace Hougaard.StarterControlAddIn;

/// <summary>
/// A blank control add-in with the plumbing in place: content and captions
/// pushed from AL, messages back to AL, three ways to size it vertically, and
/// Business Central keyboard shortcuts that keep working while focus is inside it.
/// </summary>
controladdin "Starter AddIn"
{
    Scripts =
        'src/ControlAddIn/js/height.js',
        'src/ControlAddIn/js/keyforwarder.js',
        'src/ControlAddIn/js/starter.js';
    StartupScript = 'src/ControlAddIn/js/startup.js';
    RecreateScript = 'src/ControlAddIn/js/startup.js';
    StyleSheets = 'src/ControlAddIn/css/starter.css';

    // The standard size. Business Central works the height out from these;
    // FillParent and SetHeight override it at run time.
    RequestedHeight = 300;
    MinimumHeight = 50;
    RequestedWidth = 300;
    MinimumWidth = 100;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    /// <summary>The add-in has loaded (or was recreated). Send the content and choose the height here.</summary>
    event OnControlReady();

    /// <summary>
    /// Something happened in the add-in. Raised by StarterAddIn.send(name, data) in JavaScript, and by a
    /// click on any element with a data-message attribute (its other data-* attributes are the data).
    /// </summary>
    event OnMessage(Name: Text; Data: JsonObject);

    /// <summary>
    /// The texts the content shows, as { "key": "text" }, built from AL labels so they are translated with the app.
    /// Elements name their caption with data-caption="key" (or data-caption-title, data-caption-placeholder, ...).
    /// Call it before SetHtml. Calling it again adds to the set.
    /// </summary>
    procedure SetCaptions(Captions: JsonObject);

    /// <summary>Replaces the content with an HTML page. Styles and scripts in the page are applied, so pass only HTML you trust.</summary>
    procedure SetHtml(Html: Text);

    /// <summary>Shows an image in the element with the given id. Source is a URL or a data URI.</summary>
    procedure SetImage(ElementId: Text; Source: Text);

    /// <summary>Height mode 1: the standard Business Central size, from the properties above.</summary>
    procedure UseStandardHeight();

    /// <summary>
    /// Height mode 2: fill the page the add-in is on, and follow the browser window when it is resized.
    /// Offset is the number of pixels to leave free, for the margins around the add-in; raise it if the
    /// page gets a scrollbar, lower it if there is a gap. 10 suits a page where the add-in is the only content.
    /// </summary>
    procedure FillParent(Offset: Integer);

    /// <summary>Height mode 3: an exact height in pixels.</summary>
    procedure SetHeight(Pixels: Integer);
}
