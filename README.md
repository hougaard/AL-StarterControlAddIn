# AL-Starter ControlAddIn

The best way to get going when you need to create a control add-in for AL and Microsoft Dynamics 365 Business Central.

A control add-in lets you put your own HTML, CSS and JavaScript inside a Business Central page, and have it talk to AL in both directions. Getting the first one running means wiring up several pieces that all have to agree with each other, and then solving the same handful of problems everybody runs into: the add-in is the wrong height, keyboard shortcuts stop working when it has focus, and the texts in it are not translated. This repository is an open source starter app with those pieces connected and those problems solved, so you can clone it, publish it, and start on the part that is actually yours.

## What you get

- **A blank control add-in.** It draws nothing of its own. AL sends it the content.
- **HTML and images from app resources.** The page is an `.html` file and the logo an `.svg` file in the app's resource folder. AL reads them and sends them to the add-in.
- **Captions from AL labels.** The HTML holds no text. Every text is a `Label` in AL, so it is translated with the rest of the app.
- **Three ways to set the height:** the standard Business Central size, fill the page, or an exact number of pixels set from AL.
- **Keyboard shortcuts that keep working.** Alt+Q, Alt+T, F5, Esc and the rest reach Business Central even when focus is inside the add-in.
- **Messages both ways.** AL calls procedures on the add-in, and the add-in raises events in AL.
- **Three test pages** that show the add-in on its own, on a card next to other fields, and in a FactBox.

## Requirements

- Business Central 29 or later (AL runtime 18.0)
- Visual Studio Code with the [AL Language extension](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al)
- A Business Central sandbox to publish to: an online sandbox, a Docker container, or an on-premises server

## Getting started

1. Clone this repository and open the folder in Visual Studio Code.
2. Create your own `.vscode/launch.json` that points at your sandbox. It is not checked in, because every developer's server is different. If you do not have one, run **AL: Go!** in an empty folder and copy the file it generates.
3. Run **AL: Download symbols** from the command palette.
4. Press <kbd>F5</kbd> to publish the app and open Business Central.
5. Search for **Starter Add-in Host** or **Starter Add-in Card** to open the test pages.

## The test pages

| Page | Type | What it shows |
| --- | --- | --- |
| Starter Add-in Host | `UserControlHost` | The add-in on its own, filling the page. This page type cannot have actions or fields, so the buttons that switch the height are in the HTML. |
| Starter Add-in Card | `Card` | The add-in below ordinary fields. The **Height Mode**, **Fill Offset (px)** and **Height (px)** fields control it, and **Last Message** shows what the add-in sent back. |
| Starter Add-in (FactBox) | `CardPart` | The add-in in a FactBox on the card page, held at a fixed height. |

## How it works

### Content from resources

`app.json` names a resource folder (`"resourceFolders": ["Resources"]`), and everything in it is packed into the app. Codeunit `Starter Resources` reads a file from it:

```al
CurrPage.AddIn.SetHtml(Resources.GetText('html/welcome.html'));
CurrPage.AddIn.SetImage('logo', Resources.GetImageDataUri('images/logo.svg'));
```

`SetHtml` takes a whole HTML page. Its styles are kept, its body becomes the content, and its scripts run, so pass it only HTML you trust. `SetImage` puts an image into the element with the given id; `GetImageDataUri` works for svg, png, jpg, gif and webp files.

### Captions

Write no text in the HTML. Name a caption instead:

```html
<h2 data-caption="heading"></h2>
<input data-caption-placeholder="searchHint">
```

Keep the texts as labels in AL, and send them as one JSON object before the HTML:

```al
Captions.Add('heading', HeadingLbl);
Captions.Add('searchHint', SearchHintLbl);
CurrPage.AddIn.SetCaptions(Captions);
```

`data-caption` sets the element's text, and `data-caption-<attribute>` sets any attribute (`title`, `placeholder`, `aria-label`). In JavaScript, `StarterAddIn.caption('key', value1, value2)` returns the text and fills `%1` and `%2` the way AL does. A key that AL did not send shows up as the key itself, so a missing caption is easy to find. Codeunit `Starter Demo Captions` holds the captions for the test pages.

### Height

| Procedure | Result |
| --- | --- |
| `UseStandardHeight()` | The size Business Central works out from `RequestedHeight`, `MinimumHeight` and `VerticalStretch` on the control add-in. |
| `FillParent(Offset)` | The add-in fills the page it is on, and follows the browser window when it is resized. `Offset` is the number of pixels to leave free for the margins around it. |
| `SetHeight(Pixels)` | An exact height. |

Business Central puts the add-in in an iframe and often keeps it small however much room the page has. The add-in can reach its own iframe element in the host page, so `FillParent` and `SetHeight` set the height there.

How much room the page has around the add-in depends on the page type and on what else is on the page, so `FillParent` takes the offset from you. Start with `FillParent(10)`. Raise the number if the page gets a scrollbar, and lower it if there is a gap below the add-in. The **Fill Offset (px)** field on the card test page lets you try values without republishing.

The logic is in [height.js](src/ControlAddIn/js/height.js). It relies on class names in the Business Central web client, which Microsoft can change; the two constants at the top of the file are the places to adjust.

### Keyboard shortcuts

Key presses do not cross an iframe boundary, so Business Central shortcuts stop working while focus is inside an add-in. [keyforwarder.js](src/ControlAddIn/js/keyforwarder.js) catches function keys, Alt combinations and Esc, and replays them on the host page. Esc is only forwarded when the add-in did not use it and focus is not in a field. If your add-in needs some of these keys for itself, exclude them in `classify`.

### Messages

AL to the add-in: add a `procedure` to the control add-in, and a global JavaScript function with the same name.

The add-in to AL: call `StarterAddIn.send('name', { any: 'data' })`, or give an element a `data-message` attribute and let a click send it:

```html
<button data-message="height-fixed" data-pixels="600" data-caption="height600"></button>
```

Both raise the `OnMessage(Name; Data)` event on the page.

## Files

| Path | Contents |
| --- | --- |
| [src/ControlAddIn/](src/ControlAddIn/) | The control add-in, its scripts and style sheet, and the resource reader. This is the part to keep. |
| [src/TestPages/](src/TestPages/) | The three test pages and their captions. Delete them when you have your own page. |
| [Resources/](Resources/) | The example HTML pages and the logo. |

## Make it your own

Before you build on the starter, change these values in [app.json](app.json):

| Setting | Why |
| --- | --- |
| `id` | Every app needs its own GUID. Generate a new one. |
| `name` and `publisher` | So the app shows up as yours in Extension Management. |
| `idRanges` | The starter uses 52900 to 52949. Switch to a range you own. |

Then rename the objects to match your own prefix or suffix, and change the `namespace` line at the top of each AL file.

## Building with an AI coding agent

The repository includes instructions for coding agents: [.claude/skills/al-controladdin-starter/SKILL.md](.claude/skills/al-controladdin-starter/SKILL.md). Claude Code picks the skill up by itself when you work in a clone of this repository. For any other agent, or when you are adding the add-in to a different app, point the agent at that file. It covers where things are, the rules that keep the add-in correct (captions as labels, content as resources, height modes, keyboard), how to add procedures and events, and what to rename.

## Contributing

Issues and pull requests are welcome. The goal is to stay a small, readable starting point, so changes that keep the starter easy to understand are preferred over ones that add features most add-ins will not need.

## License

Released under the [MIT License](LICENSE). Use it for anything, including commercial work.
