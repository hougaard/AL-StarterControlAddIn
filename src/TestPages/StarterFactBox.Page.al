namespace Hougaard.StarterControlAddIn;

/// <summary>
/// Test page 3: the add-in in a FactBox. A FactBox is only as tall as its
/// content, so the part starts at an exact height with SetHeight. The buttons in
/// it switch the mode; FillParent in a FactBox takes over the whole FactBox pane.
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
                    ApplyHeight();
                end;

                trigger OnMessage(Name: Text; Data: JsonObject)
                var
                    Pixels: Integer;
                begin
                    case Name of
                        'height-standard':
                            HeightMode := HeightMode::Standard;
                        'height-fill':
                            HeightMode := HeightMode::"Fill Parent";
                        'height-fixed':
                            if Evaluate(Pixels, Data.GetText('pixels')) then begin
                                HeightMode := HeightMode::Fixed;
                                HeightPixels := Pixels;
                            end;
                        'hello':
                            Message(HelloMsg);
                    end;
                    ApplyHeight();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        HeightMode := HeightMode::Fixed;
        HeightPixels := 190;
    end;

    /// <summary>Only called from the add-in's own triggers, so the add-in is known to be ready.</summary>
    local procedure ApplyHeight()
    begin
        case HeightMode of
            HeightMode::Standard:
                CurrPage.AddIn.UseStandardHeight();
            HeightMode::"Fill Parent":
                CurrPage.AddIn.FillParent(0); // in a FactBox: the whole FactBox pane
            HeightMode::Fixed:
                CurrPage.AddIn.SetHeight(HeightPixels);
        end;
    end;

    var
        Resources: Codeunit "Starter Resources";
        Captions: Codeunit "Starter Demo Captions";
        HeightMode: Enum "Starter Height Mode";
        HeightPixels: Integer;
        HelloMsg: Label 'Hello from AL. The FactBox add-in raised OnMessage and this trigger answered.';
}
