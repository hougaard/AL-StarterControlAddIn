namespace Hougaard.StarterControlAddIn;

/// <summary>
/// Test page 3: the add-in in a FactBox. A FactBox has no height of its own to
/// fill, so the part sets an exact height with SetHeight.
/// </summary>
page 52902 "Starter FactBox"
{
    Caption = 'Starter Add-in';
    PageType = CardPart;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(AddIn; "Starter AddIn")
            {
                trigger OnControlReady()
                begin
                    CurrPage.AddIn.SetCaptions(Captions.Get()); // before SetHtml: the page is painted with them
                    CurrPage.AddIn.SetHtml(Resources.GetText('html/factbox.html'));
                    CurrPage.AddIn.SetImage('logo', Resources.GetImageDataUri('images/logo.svg'));
                    CurrPage.AddIn.SetHeight(190);
                end;

                trigger OnMessage(Name: Text; Data: JsonObject)
                begin
                    if Name = 'hello' then
                        Message(HelloMsg);
                end;
            }
        }
    }

    var
        Resources: Codeunit "Starter Resources";
        Captions: Codeunit "Starter Demo Captions";
        HelloMsg: Label 'Hello from AL. The FactBox add-in raised OnMessage and this trigger answered.';
}
