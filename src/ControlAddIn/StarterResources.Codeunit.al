namespace Hougaard.StarterControlAddIn;

using System.Text;

/// <summary>
/// Reads the files in the app's resource folder (see "resourceFolders" in app.json)
/// in the shape the add-in wants them. Paths are relative to that folder.
/// </summary>
codeunit 52900 "Starter Resources"
{
    /// <summary>A text resource, such as an HTML page, as text.</summary>
    procedure GetText(ResourcePath: Text): Text
    begin
        exit(NavApp.GetResourceAsText(ResourcePath, TextEncoding::UTF8));
    end;

    /// <summary>An image resource (svg, png, jpg, gif, webp) as a data URI, ready for SetImage or an img src.</summary>
    procedure GetImageDataUri(ResourcePath: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        ImageStream: InStream;
        DataUriTok: Label 'data:%1;base64,%2', Locked = true;
    begin
        NavApp.GetResource(ResourcePath, ImageStream);
        exit(StrSubstNo(DataUriTok, GetMimeType(ResourcePath), Base64Convert.ToBase64(ImageStream)));
    end;

    local procedure GetMimeType(ResourcePath: Text): Text
    begin
        case ResourcePath.Substring(ResourcePath.LastIndexOf('.') + 1).ToLower() of
            'svg':
                exit('image/svg+xml');
            'png':
                exit('image/png');
            'jpg', 'jpeg':
                exit('image/jpeg');
            'gif':
                exit('image/gif');
            'webp':
                exit('image/webp');
        end;
        exit('application/octet-stream');
    end;
}
