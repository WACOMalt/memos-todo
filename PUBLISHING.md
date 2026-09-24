# KDE Store publishing information

Use this file to keep the KDE Store listing consistent between releases.

## Product

- **Store page**: store.kde.org (log in with the OpenDesktop account)
- **Product name**: Memos ToDo
- **Category**: Plasma → Plasma 6 Applets
- **License**: MIT
- **Homepage / Source**: https://github.com/WACOMalt/memos-todo/tree/linux-kde

## Description

Copy this text into the store description field:

Memos ToDo shows an interactive to-do list from a memo on your self-hosted
UseMemos server (https://usememos.com).

The panel label cycles through the lines of the memo. Click it to open the
list. Click a task to check or uncheck it, click the trash icon to delete
it, and type in the "New task..." field to add one. The changes go to your
Memos server at once. "Open in Browser" opens the memo on the server.

Place the widget on the desktop to show the list as a note. Choose the
Plasma theme, a translucent background, one of eight note colors, or your
own background and text colors.

A line that starts with ☐ is an open task and a line that starts with ☑
is a completed task, so the list stays readable in the Memos web interface.
The same memo works with the Memos ToDo applet for Cinnamon, the Windows
taskbar overlay and the Android app and widget.

Settings: server URL, access token, memo ID, refresh interval, popup and
panel font sizes, popup width, fixed panel width, text cycle interval,
slide duration, whether to show completed tasks in the panel and in the
popup, and the colors, opacity and font size of the desktop widget. Translated into Arabic, Chinese (Simplified), French, Hindi,
Japanese and Spanish.

Requirements: KDE Plasma 6, a UseMemos server, an API access token, and
the ID of the memo to show.

Source: https://github.com/WACOMalt/memos-todo/tree/linux-kde

## Logo

- `logo/logo.svg`: the source file
- `logo/logo.png`: the 512x512 render for the store logo field

Render a new PNG after a change to the SVG:

```
rsvg-convert -w 512 -h 512 logo/logo.svg -o logo/logo.png
```

## Screenshots

- `screenshots/panel.png`: the panel label
- `screenshots/popup.png`: the popup
- `screenshots/widget.png`: the desktop widget in the Blue style, at an angle
- `screenshots/settings.png`: the General settings page
- `screenshots/aboutpanel.png`: the About page of the settings

The screenshots show a demo memo and no server address, token or memo ID.
Make new screenshots when the panel label, the popup, the desktop widget or
the settings change.

## How to publish an update

1. Increase `Version` in `plasmoid/bsums.xyz.memos-todo/metadata.json`.
2. If strings changed, run `po/update-pot.sh` and update the translations.
3. Run the tests:

   ```
   tests/run-tests.sh
   ```

4. Build the package:

   ```
   ./make-plasmoid.sh
   ```

5. Open the product page on store.kde.org and go to the Files section.
6. Upload `dist/memos-todo-<version>.plasmoid`.
7. Update the description text if the behavior changed. Keep this file and
   the store text identical.
8. Commit and push the version change to GitHub, then tag and release:

   ```
   git tag -a vX.Y.Z-kde -m "Memos ToDo for KDE X.Y.Z"
   git push origin vX.Y.Z-kde
   gh release create vX.Y.Z-kde dist/memos-todo-X.Y.Z.plasmoid
   ```

Users receive the update through Discover and the Plasma widget browser.
