namespace Hougaard.StarterControlAddIn;

/// <summary>
/// Every text the test pages' HTML shows, as the caption set for SetCaptions.
/// The HTML holds no text of its own: an element names a key from this set
/// (data-caption="key") and gets the label, translated like any other label.
/// </summary>
codeunit 52901 "Starter Demo Captions"
{
    /// <summary>The complete caption set for "Starter AddIn".SetCaptions.</summary>
    procedure Get() Captions: JsonObject
    begin
        // welcome.html
        Captions.Add('title', TitleTok);
        Captions.Add('frameSize', FrameSizeLbl);
        Captions.Add('captionsHeading', CaptionsHeadingLbl);
        Captions.Add('captionsText', CaptionsTextLbl);
        Captions.Add('resourcesHeading', ResourcesHeadingLbl);
        Captions.Add('resourcesText', ResourcesTextLbl);
        Captions.Add('heightHeading', HeightHeadingLbl);
        Captions.Add('heightText', HeightTextLbl);
        Captions.Add('heightStandard', HeightStandardLbl);
        Captions.Add('heightFill', HeightFillLbl);
        Captions.Add('height300', Height300Lbl);
        Captions.Add('height600', Height600Lbl);
        Captions.Add('keysHeading', KeysHeadingLbl);
        Captions.Add('keysText', KeysTextLbl);
        Captions.Add('keysPlaceholder', KeysPlaceholderLbl);
        Captions.Add('keysFieldLabel', KeysFieldLabelLbl);
        Captions.Add('messageHeading', MessageHeadingLbl);
        Captions.Add('sayHello', SayHelloLbl);

        // factbox.html
        Captions.Add('factBoxTitle', FactBoxTitleLbl);
        Captions.Add('factBoxText', FactBoxTextLbl);
    end;

    var
        TitleTok: Label 'AL-Starter ControlAddIn', Locked = true;
        FrameSizeLbl: Label 'The dashed border is the edge of the add-in. Frame size:';
        CaptionsHeadingLbl: Label 'Captions from AL labels';
        CaptionsTextLbl: Label 'No text on this page is written in the HTML. Each element names a caption, and AL sends the texts with SetCaptions, so they are translated like any other label.', Comment = 'SetCaptions is a procedure name; do not translate it.';
        ResourcesHeadingLbl: Label 'Content from app resources';
        ResourcesTextLbl: Label 'This page and the logo are files in the resource folder of the app. AL reads them and sends them to the add-in with SetHtml and SetImage.', Comment = 'SetHtml and SetImage are procedure names; do not translate them.';
        HeightHeadingLbl: Label 'Vertical size';
        HeightTextLbl: Label 'Each button raises OnMessage in AL, and AL answers by calling a procedure on the add-in.', Comment = 'OnMessage is an event name; do not translate it.';
        HeightStandardLbl: Label 'Standard';
        HeightFillLbl: Label 'Fill parent';
        Height300Lbl: Label '300 px', Comment = 'px is the abbreviation for pixels.';
        Height600Lbl: Label '600 px', Comment = 'px is the abbreviation for pixels.';
        KeysHeadingLbl: Label 'Keyboard shortcuts';
        KeysTextLbl: Label 'Click anywhere in the add-in, then press Alt+Q (Tell Me) or Alt+T (My Settings). The key press is forwarded to Business Central. Typing in a field still works, and Esc in a field does not close the page.';
        KeysPlaceholderLbl: Label 'Type here, then try Alt+Q';
        KeysFieldLabelLbl: Label 'Test field';
        MessageHeadingLbl: Label 'Talk to AL';
        SayHelloLbl: Label 'Say hello';
        FactBoxTitleLbl: Label 'Add-in in a FactBox';
        FactBoxTextLbl: Label 'Held at 190 pixels by SetHeight(190).', Comment = 'SetHeight(190) is code; do not translate it.';
}
