namespace Hougaard.StarterControlAddIn;

/// <summary>The three ways the add-in can be sized vertically.</summary>
enum 52900 "Starter Height Mode"
{
    Extensible = false;

    value(0; Standard)
    {
        Caption = 'Standard';
    }
    value(1; "Fill Parent")
    {
        Caption = 'Fill Parent';
    }
    value(2; Fixed)
    {
        Caption = 'Fixed';
    }
}
