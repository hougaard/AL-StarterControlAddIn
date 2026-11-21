---
name: al-controladdin-starter
description: Build a Business Central control add-in (an AL controladdin object with HTML, CSS and JavaScript shown inside a page) on top of the AL-Starter ControlAddIn repository. Use this whenever the task involves a control add-in, a usercontrol, a UserControlHost page, or putting custom HTML, JavaScript, charts, editors or any other custom UI inside a Business Central page, and also when fixing an add-in that has the wrong height, swallows keyboard shortcuts such as Alt+Q, or shows untranslated text. Use it even if the user does not mention the starter by name.
---

# Building a control add-in with AL-Starter ControlAddIn

This repository is a working Business Central app that contains one blank control add-in with the hard parts already solved. Build on it instead of writing an add-in from scratch: the things it solves (height, keyboard shortcuts, translation, content loading) are the things a fresh add-in gets wrong, and they only show up once the add-in is running in a real page.

Read [README.md](../../../README.md) for the feature overview. This document is about how to work in the code.

## The mental model

A control add-in is an iframe that Business Central puts inside a page. Inside the iframe is a document with one empty element, `<div id="controlAddIn">`, and the scripts and style sheets the `controladdin` object lists. Two channels cross the boundary:

- **AL to JavaScript:** each `procedure` on the `controladdin` object calls a global JavaScript function with the same name.
- **JavaScript to AL:** `Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('EventName', [arguments])` raises the `event` with that name, which the page handles as a trigger on the `usercontrol`.

The starter's add-in holds no state that matters. The page pushes everything in its `OnControlReady` trigger: captions, then content, then the height. Keep it that way. Business Central can recreate the control, and the startup script then raises `OnControlReady` again; a page that pushes everything there ends up correct in both cases without extra code.

## Where things are

| Path | What it is | What to do with it |
| --- | --- | --- |
| `src/ControlAddIn/StarterAddIn.ControlAddIn.al` | The `controladdin` object: script list, size properties, events, procedures | Keep. Add your own procedures and events here. |
| `src/ControlAddIn/js/starter.js` | Content, captions, messages, and the global functions the AL procedures call | Keep. Add the JavaScript side of new procedures at the bottom. |
| `src/ControlAddIn/js/height.js` | The three height modes | Keep as is. |
| `src/ControlAddIn/js/keyforwarder.js` | Sends Business Central shortcuts from the iframe to the host page | Keep as is, apart from `classify` (see Keyboard). |
| `src/ControlAddIn/js/startup.js` | Startup and recreate script; raises `OnControlReady` | Keep. |
| `src/ControlAddIn/css/starter.css` | Base styles for the iframe document | Keep; put feature styles in your own file. |
| `src/ControlAddIn/StarterResources.Codeunit.al` | Reads files from the app's resource folder | Keep. |
| `src/TestPages/` | Three example pages and their captions codeunit | Use as patterns, then delete. |
| `Resources/` | Example HTML pages and a logo | Replace with your own. |

## Two ways to use the repository

**Starting a new app.** Work in a clone of this repository. Rename it first (see Renaming), then replace the test pages and example resources with the real ones.

**Adding an add-in to an existing app.** Copy `src/ControlAddIn/` into the app, and merge two things by hand:

- `app.json` needs `"resourceFolders": ["Resources"]` (or the app's existing resource folder; then put the HTML and images there).
- The paths in `Scripts`, `StartupScript`, `RecreateScript` and `StyleSheets` are relative to the project root, not to the `.al` file. If the folder lands somewhere other than `src/ControlAddIn/`, update every path.

Give the copied objects IDs from the target app's range and its naming affix. The resource reader relies on `resourceFolders` and `NavApp.GetResource`, which older AL runtimes do not have (the starter itself is on runtime 18.0). If the target app does not compile with them, tell the user its runtime is too old for app resources instead of working around it silently.

## The add-in's contract

| Member | Purpose |
| --- | --- |
| `event OnControlReady()` | The add-in loaded or was recreated. Push everything here. |
| `event OnMessage(Name: Text; Data: JsonObject)` | Something happened in the add-in. |
| `procedure SetCaptions(Captions: JsonObject)` | The texts, as `{ "key": "text" }`. Call before `SetHtml`. Calling again adds to the set. |
| `procedure SetHtml(Html: Text)` | Replaces the content with an HTML page. |
| `procedure SetImage(ElementId: Text; Source: Text)` | Sets the image of the element with that id. |
| `procedure UseStandardHeight()` | Height from the `controladdin` size properties. |
| `procedure FillParent(Offset: Integer)` | Fill the page, leaving `Offset` pixels free. |
| `procedure SetHeight(Pixels: Integer)` | An exact height. |

A typical page:

```al
usercontrol(AddIn; "Starter AddIn")
{
    trigger OnControlReady()
    begin
        AddInReady := true;
        CurrPage.AddIn.SetCaptions(Captions.Get());
        CurrPage.AddIn.SetHtml(Resources.GetText('html/mypage.html'));
        CurrPage.AddIn.SetImage('logo', Resources.GetImageDataUri('images/logo.svg'));
        CurrPage.AddIn.FillParent(10);
    end;

    trigger OnMessage(Name: Text; Data: JsonObject)
    begin
        case Name of
            'save':
                SaveIt(Data);
        end;
    end;
}
```

Calling an add-in procedure before `OnControlReady` has fired is a runtime error, because the iframe does not exist yet. Any code path that can run earlier (`OnOpenPage`, `OnAfterGetCurrRecord`, a field's `OnValidate`) has to check a ready flag first, as `ApplyHeight` in `src/TestPages/StarterCard.Page.al` does. For data that follows the record, store what to show and send it from both `OnAfterGetCurrRecord` (when ready) and `OnControlReady`.

## Rules that keep the add-in correct

### No user-visible text in HTML or JavaScript

Every text a user reads is a `Label` in AL. Labels are what Business Central translates; text written in an HTML file or a script is invisible to the translation tools and stays English forever. In HTML, name the caption and leave the element empty:

```html
<h2 data-caption="heading"></h2>
<input data-caption-placeholder="searchHint" data-caption-aria-label="searchLabel">
<button data-message="save" data-caption="save" data-caption-title="saveTip"></button>
```

In AL, keep one codeunit per add-in that builds the set (pattern: `src/TestPages/StarterDemoCaptions.Codeunit.al`):

```al
procedure Get() Captions: JsonObject
begin
    Captions.Add('heading', HeadingLbl);
    Captions.Add('rowCount', RowCountLbl); // 'Rows: %1'
end;
```

In JavaScript, use `StarterAddIn.caption('rowCount', 12)`; it fills `%1` to `%9` like AL does.

Things to know:

- `data-caption` sets `textContent`, which removes the element's children. Put it on leaf elements. To mix translated text with markup, split the sentence into several elements or build it in script from `caption()`.
- A key AL did not send is displayed as the key itself. If a key name shows up in the UI, the label is missing from the captions codeunit.
- Code identifiers, file paths and numbers are not captions and can stay in the HTML.
- Add a `Comment` to labels that contain names a translator must leave alone, and `Locked = true` to labels that must not be translated at all.
- Console diagnostics are for developers and stay in English in the script.

### Content lives in resource files

Put HTML pages and images in the resource folder and load them with codeunit `Starter Resources`. Paths are relative to the resource folder (`'html/mypage.html'`, not `'Resources/html/mypage.html'`). A resource page can be a whole HTML document: `SetHtml` keeps the `<style>` elements from its head, uses the body as the content, and runs its scripts.

`SetHtml` runs whatever scripts the HTML contains, so it is only for HTML that ships with the app. Do not build HTML by concatenating record data into it; a customer name containing markup would then run as code. Send data separately (see Adding to the contract) and put it in the page with `textContent`.

A script in a resource page runs again each time `SetHtml` is called. Assign handlers (`window.onresize = ...`) or attach them to elements inside the content, so a reload does not stack listeners.

`GetImageDataUri` embeds the image in the message as base64, which suits logos and icons. For large or numerous images, list them in the `Images` property of the `controladdin` and resolve them in script with `Microsoft.Dynamics.NAV.GetImageResource('path')`.

### Pick the height mode by page type

| Where the add-in is | Mode |
| --- | --- |
| `UserControlHost` page, or a `Card` where the add-in is the main content | `FillParent(10)` |
| `Card` with fields above the add-in | `FillParent(Offset)` or `SetHeight(Pixels)` |
| FactBox (`CardPart`) that shares the pane with other FactBoxes | `SetHeight(Pixels)` |
| FactBox (`CardPart`) that should take over the whole FactBox pane | `FillParent(0)` |
| The standard size is good enough | `UseStandardHeight()`, or call nothing |

Do not write your own code that reaches into the host page to size the frame; `height.js` already does it, keeps the listener tidy when the page closes, and restores the original size. It depends on class names in the Business Central web client (`control-addin-form`, `ms-nav-layout-rolecenter`, `ms-nav-layout-factbox-pane-container`), which is a reason to keep that dependency in one file.

In a FactBox, `FillParent` measures the FactBox pane instead of the page: the add-in becomes as tall as the pane, less the pane's own header and the part's caption (the `FACTBOX_CHROME` constant in `height.js`). Other FactBoxes in the same pane end up below it, out of view until the user scrolls; if they should stay visible, pass the height they need as the offset, or use `SetHeight`. Pattern: `src/TestPages/StarterFactBox.Page.al`.

The right `FillParent` offset depends on the page and cannot be worked out without looking at it in a browser. Start with 10. Too small gives the page a scrollbar, too large leaves a gap. Tell the user the value is a starting point to adjust; the **Fill Offset (px)** field on the card test page lets them try values without republishing. Fill mode follows browser window resizes only, so it does not refit when a FastTab above the add-in is collapsed.

`SetHeight` sets the frame's minimum height as well as its height, so a small value is not held back by `MinimumHeight` on the `controladdin`. `FillParent` leaves the minimum alone.

### Keyboard

Leave the key forwarder installed. Without it, Alt+Q, Alt+T, F5, Esc and the other Business Central shortcuts do nothing while focus is in the add-in, and users experience that as the page being broken.

The forwarder takes all function keys and all Alt+letter and Alt+digit combinations. If the add-in needs one of those for itself, return `null` for it in `classify` in `keyforwarder.js`. Esc is forwarded only when no handler in the add-in called `preventDefault` and focus is not in a field, so an add-in popup that closes on Esc has to call `preventDefault` when it does.

## Adding to the contract

**A message from the add-in to AL** needs no new code for simple cases. Give an element a `data-message` attribute; a click raises `OnMessage` with the element's other `data-*` attributes as the data. From script, call `StarterAddIn.send('name', { key: value })`.

- Values from `data-*` attributes arrive as text. `data-pixels="600"` is `"600"`, so in AL use `Evaluate(Pixels, Data.GetText('pixels'))`.
- A page variable changed in an add-in trigger is not redrawn by itself. Call `CurrPage.Update(false)` at the end of the trigger if fields on the page should show the new value.

**A new procedure (AL to the add-in)** has two halves that must agree on the name:

```al
// StarterAddIn.ControlAddIn.al
procedure ShowRows(Rows: JsonArray);
```

```js
// bottom of starter.js, with the other procedures
window.ShowRows = rows => window.MyFeature.showRows(rows);
```

Put the feature itself in a new script file and add that file to the `Scripts` list of the `controladdin`. Keep `starter.js` as the one place where the AL-facing names are bound, so the contract can be read in a single spot. Scripts load in the order listed, then the startup script runs.

**A new event (the add-in to AL)** is worth adding when `OnMessage` would carry structured data that deserves named, typed parameters:

```al
event OnRowSelected(RowNo: Integer; Key: Text);
```

```js
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnRowSelected', [rowNo, key], false);
```

The array must match the event's parameters in number and order. Parameters that cross the boundary cleanly are `Text`, `Integer`, `Decimal`, `Boolean`, `JsonObject` and `JsonArray`; send anything else (dates, records, enums) as text or inside JSON.

## Page types

- **`UserControlHost`** holds exactly one `usercontrol` and nothing else: no fields, no actions, no FactBoxes. Any command the user needs has to be a control in the HTML that comes back through `OnMessage`. Pattern: `src/TestPages/StarterHost.Page.al`.
- **`Card`** can have fields, actions and FactBoxes around the add-in. Pattern: `src/TestPages/StarterCard.Page.al`.
- **`CardPart`** is how the add-in becomes a FactBox or a Role Center part. Pattern: `src/TestPages/StarterFactBox.Page.al`.

Each `usercontrol` is its own iframe with its own copy of the scripts, so two instances on one page (the card and its FactBox in the test pages) do not share JavaScript state.

## Renaming

When the starter becomes a real app, change all of these together, because a half-renamed app still compiles and then collides with another copy of the starter at install time:

1. `app.json`: a new `id` (GUID), `name`, `publisher`, and an `idRanges` the publisher owns. Renumber the objects into it.
2. The `namespace` line at the top of every `.al` file.
3. Object names (`"Starter AddIn"`, `"Starter Resources"`, the pages), with the publisher's affix.
4. Optional: the JavaScript names (`StarterAddIn`, `StarterHeight`, `StarterKeyForwarder`) and the `[Starter AddIn]` console prefix. They live inside the iframe, so they cannot clash with anything; rename them for tidiness only, and if you do, rename every reference.

Procedure and event names are part of the contract: renaming one in AL means renaming the global function or the `InvokeExtensibilityMethod` string to match.

## Checking your work

What can be checked without Business Central:

- **Compile.** Use the AL compiler (`alc.exe`, in the `bin` folder of the AL Language extension under the VS Code extensions directory) with `/project:<folder> /packagecachepath:<folder>/.alpackages`, or the AL build tooling available in the session. A clean compile also confirms that every script and style sheet path in the `controladdin` exists.
- **Script syntax.** `node --check <file>` for each JavaScript file.
- **Captions.** Every `data-caption` and `data-caption-*` value in the HTML, and every key passed to `caption()`, should have a `Captions.Add` with the same key.

What cannot: how the add-in looks and behaves in a page. Height, the fill offset, shortcut forwarding and layout all depend on the live web client. Unless you have published the app and looked at it, say so plainly and tell the user what to try: open the page, resize the browser window, press Alt+Q with focus in the add-in, and adjust the fill offset.

After republishing, a browser can keep serving the previous script or style sheet. If a change does not show up, reload the page with the cache bypassed before concluding that the code is wrong.
