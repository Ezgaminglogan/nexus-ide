# NEXUS IDE: the 3D Raspberry Pi board

The Raspberry Pi panel (in the editor, and on the full-screen terminal on phones) has a **2D | 3D** switch, and NEXUS remembers the choice. In 3D, the panel shows a real Raspberry Pi 3 model:

- **Turn it:** drag with a finger or the mouse.
- **Zoom:** pinch, or use the mouse wheel.
- **Reset the view:** double-tap, or use the ⟲ button.
- **Live pins on the real header:** the simulator's pins sit on the model's 40-pin header.
  - A GPIO set HIGH glows red.
  - Inputs are blue; touch and hold one to press it, exactly like the 2D board.
  - Power pins (5V, 3V3) and GND have their own colours.
  - Every pin has a tooltip with its physical number and GPIO number.
- **Pins hide when you turn the board upside down,** since the header is then out of sight.

## How it works (`lib/ui/widgets/pi3d.dart`)

**No WebView and no new library:** Flutter draws the model itself, so it works offline and the same way on Windows and Android.

- **Loading:** `PiModel.load()` reads `assets/raspi/raspberry_pi_3.glb` once. It takes the positions, normals, texture coordinates and indices of the textured board (≈13,000 triangles), the small plain part, and the JPEG texture.
- **Drawing:** each frame turns the vertices with the current yaw and tilt and shades them by how much they face you. It sorts the triangles far to near (painter's algorithm) and draws them with one `Canvas.drawVertices` call over the texture.
- **The header:** its position was measured from the mesh. The pin tips sit at height 0.583, in 20 columns from x = −3.30 to 1.34 (0.244 apart, 2.54 mm to scale) and in two rows: inner y = 2.228 (odd pins) and outer y = 2.464 (even pins).
  - Pin 1 is at the end away from the USB ports, as on a real Pi 3.
  - `piPinPosition()` turns a physical pin number into those coordinates, so the pins follow the board as it turns.
- **Pin presses** use raw pointer down/up. A press counts the moment you touch the pin, even though the board itself can be dragged.

## Credit (required by the license)

The model is **"Raspberry Pi 3" by JoSaCo**, from [Sketchfab](https://sketchfab.com/3d-models/raspberry-pi-3-2d308283fc0f4d27b81f17a2793c5c4d), licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), and used unchanged.

The credit is shown under the 3D board in the app, in `assets/raspi/CREDITS.md`, and here. The license and author also appear in the model file's own metadata.

## Tests

`test/raspi_test.dart`:
- The model and its texture load.
- All 40 pins are placed on the header.
- Holding physical pin 11 presses GPIO 17.
- Dragging moves the pins with the board.
- The 2D switch returns to the flat board and is remembered.

Screenshots: `docs/screenshots/raspi_3d.png` and `raspi_3d_turned.png`.

**Not tested on a phone:** turning speed and gestures were checked on the Windows PC and in the test engine only.
