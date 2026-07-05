# 🧊 Cube Solver

A self-contained website that solves any **3×3×3 Rubik's cube**, with two input methods:

- **📷 Scan** — point your camera at the cube and capture each of the six faces. Colors are
  detected automatically by comparing every sticker to the six *center* stickers, so it
  auto-calibrates to your cube and lighting.
- **🎨 Manual input** — paint the cube on an unfolded net with a color palette.

**Any color scheme works.** The solver never assumes white-opposite-yellow etc. — face
identity comes from the center stickers, and the six palette colors are fully editable
(click the ✎ dot on a swatch). Stickerless, pastel, mirrored-scheme, or custom cubes all solve fine.

Solutions come from the **Kociemba two-phase algorithm** ([cubejs](https://github.com/ldez/cubejs),
MIT license, vendored in `lib/`) and are typically **22 moves or fewer**. The solution can be
stepped through move-by-move with an animated net view, or copied as standard notation.

Invalid inputs are caught with specific explanations before solving (wrong color counts,
impossible pieces, twisted corner, flipped edge, swapped-piece parity).

## Running it

It's a static site — no build step. Serve the folder over HTTP (a web worker is used for
the solver, so opening `index.html` directly via `file://` won't work in most browsers):

```bash
cd cube-solver
python3 -m http.server 8080
# open http://localhost:8080
```

Notes:
- The camera requires a **secure context**: HTTPS or `http://localhost`.
- The solver takes a few seconds to initialize (it generates its lookup tables in a
  web worker) — the status chip at the top turns green when it's ready.

## Files

| File | Purpose |
|---|---|
| `index.html` / `style.css` | UI (tabs for scan & manual input, net editor, solution playback) |
| `app.js` | App logic: net editor, camera scanning + CIELAB color classification, state validation, solution playback |
| `worker.js` | Web worker that initializes and runs the solver off the main thread |
| `lib/cube.js`, `lib/solve.js` | Vendored cubejs engine (MIT) |
