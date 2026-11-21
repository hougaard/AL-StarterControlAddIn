namespace Hougaard.StarterControlAddIn;

/// <summary>
/// Test page 1: the add-in on its own. A UserControlHost page holds one user
/// control and nothing else (no actions, no fields), so the buttons that switch
/// the height mode are in the HTML and come back through OnMessage.
/// </summary>
page 52900 "Starter Host"
{
    Caption = 'Starter Add-in Host';
    PageType = UserControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'control add-in,controladdin,starter';

    layout
    {
        area(Content)
        {
            usercontrol(AddIn; "Starter AddIn")
            {
                trigger OnControlReady()
                begin
                    CurrPage.AddIn.SetCaptions(Captions.Get()); // before SetHtml: the page is painted with them
                    CurrPage.AddIn.SetHtml(Resources.GetText('html/welcome.html'));
                    CurrPage.AddIn.SetImage('logo', Resources.GetImageDataUri('images/logo.svg'));
                    CurrPage.AddIn.FillParent(FillOffset());
                end;

                trigger OnMessage(Name: Text; Data: JsonObject)
                var
                    Pixels: Integer;
                begin
                    case Name of
                        'height-standard':
                            CurrPage.AddIn.UseStandardHeight();
                        'height-fill':
                            CurrPage.AddIn.FillParent(FillOffset());
                        'height-fixed':
                            if Evaluate(Pixels, Data.GetText('pixels')) then
                                CurrPage.AddIn.SetHeight(Pixels);
                        'hello':
                            Message(HelloMsg);
                    end;
                end;
            }
        }
    }

    /// <summary>The pixels FillParent leaves free below the add-in on this page.</summary>
    local procedure FillOffset(): Integer
    begin
        exit(10);
    end;

    var
        Resources: Codeunit "Starter Resources";
        Captions: Codeunit "Starter Demo Captions";
        HelloMsg: Label 'Hello from AL. The add-in raised OnMessage and this trigger answered.';
}
