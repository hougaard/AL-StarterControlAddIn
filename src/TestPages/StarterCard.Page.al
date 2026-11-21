namespace Hougaard.StarterControlAddIn;

/// <summary>
/// Test page 2: the add-in on a card with other things around it. The fields
/// above it choose the height mode and its numbers, and the FactBox shows a second copy of the
/// add-in at a fixed height.
/// </summary>
page 52901 "Starter Card"
{
    Caption = 'Starter Add-in Card';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'control add-in,controladdin,starter';

    layout
    {
        area(Content)
        {
            group(VerticalSize)
            {
                Caption = 'Vertical Size';

                field(HeightModeField; HeightMode)
                {
                    Caption = 'Height Mode';
                    ToolTip = 'Specifies how the add-in below is sized: the standard Business Central height, filling the page, or a fixed number of pixels.';

                    trigger OnValidate()
                    begin
                        ApplyHeight();
                    end;
                }
                field(FillOffsetField; FillOffset)
                {
                    Caption = 'Fill Offset (px)';
                    ToolTip = 'Specifies the number of pixels that Fill Parent leaves free below the add-in. Raise it if the page gets a scrollbar. Entering a value switches the height mode to Fill Parent.';

                    trigger OnValidate()
                    begin
                        HeightMode := HeightMode::"Fill Parent";
                        ApplyHeight();
                    end;
                }
                field(HeightPixelsField; HeightPixels)
                {
                    Caption = 'Height (px)';
                    ToolTip = 'Specifies the height of the add-in in pixels. Entering a value switches the height mode to Fixed.';
                    MinValue = 50;

                    trigger OnValidate()
                    begin
                        HeightMode := HeightMode::Fixed;
                        ApplyHeight();
                    end;
                }
                field(LastMessageField; LastMessage)
                {
                    Caption = 'Last Message';
                    ToolTip = 'Specifies the name of the last message the add-in sent to AL.';
                    Editable = false;
                }
            }
            usercontrol(AddIn; "Starter AddIn")
            {
                trigger OnControlReady()
                begin
                    AddInReady := true;
                    LoadContent();
                    ApplyHeight();
                end;

                trigger OnMessage(Name: Text; Data: JsonObject)
                var
                    Pixels: Integer;
                begin
                    LastMessage := Name;
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
                    CurrPage.Update(false); // show the new field values
                end;
            }
        }
        area(FactBoxes)
        {
            part(StarterFactBox; "Starter FactBox")
            {
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReloadContent)
            {
                Caption = 'Reload Content';
                ToolTip = 'Send the HTML page and the image to the add-in again.';
                Image = Refresh;

                trigger OnAction()
                begin
                    if AddInReady then
                        LoadContent();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ReloadContent_Promoted; ReloadContent)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        HeightPixels := 400;
        FillOffset := 10;
    end;

    local procedure LoadContent()
    begin
        CurrPage.AddIn.SetCaptions(Captions.Get()); // before SetHtml: the page is painted with them
        CurrPage.AddIn.SetHtml(Resources.GetText('html/welcome.html'));
        CurrPage.AddIn.SetImage('logo', Resources.GetImageDataUri('images/logo.svg'));
    end;

    local procedure ApplyHeight()
    begin
        if not AddInReady then
            exit;
        case HeightMode of
            HeightMode::Standard:
                CurrPage.AddIn.UseStandardHeight();
            HeightMode::"Fill Parent":
                CurrPage.AddIn.FillParent(FillOffset);
            HeightMode::Fixed:
                CurrPage.AddIn.SetHeight(HeightPixels);
        end;
    end;

    var
        Resources: Codeunit "Starter Resources";
        Captions: Codeunit "Starter Demo Captions";
        HeightMode: Enum "Starter Height Mode";
        HeightPixels: Integer;
        FillOffset: Integer;
        LastMessage: Text;
        AddInReady: Boolean;
        HelloMsg: Label 'Hello from AL. The add-in raised OnMessage and this trigger answered.';
}
