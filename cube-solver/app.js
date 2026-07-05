/* Cube Solver — scan or manually enter a 3x3x3 cube, solve with Kociemba two-phase.
 * Faces use the standard URFDLB convention. Colors are decoupled from faces:
 * each face's identity comes from its center sticker, and the palette (the six
 * colors) is fully editable / auto-calibrated from the camera, so any color
 * scheme solves fine. */

'use strict';

const FACES = ['U', 'R', 'F', 'D', 'L', 'B'];
const FACE_NAMES = { U: 'Up', R: 'Right', F: 'Front', D: 'Down', L: 'Left', B: 'Back' };
const DEFAULT_PALETTE = ['#ffffff', '#e03131', '#2f9e44', '#ffd43b', '#ff922b', '#1971c2'];
const SOLVED = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';

const $ = (id) => document.getElementById(id);

// ---------------------------------------------------------------- state
let palette = DEFAULT_PALETTE.slice();
// stickers[face] = 9 palette indices (or -1 = unset); index 4 (center) is fixed
const stickers = {};
FACES.forEach((f, i) => {
  stickers[f] = Array(9).fill(-1);
  stickers[f][4] = i;
});
let selectedTool = 0; // palette index, or 'erase'

// ---------------------------------------------------------------- solver worker
let solverReady = false;
let solving = false;
const worker = new Worker('worker.js');

worker.onmessage = (e) => {
  const msg = e.data;
  if (msg.type === 'ready') {
    solverReady = true;
    setStatus('ready', '✅ Solver ready');
    updateSolveButton();
  } else if (msg.type === 'solution') {
    solving = false;
    updateSolveButton();
    showSolution(msg.solution.trim());
  } else if (msg.type === 'error') {
    solving = false;
    updateSolveButton();
    showInputError('Solver error: ' + msg.message);
  }
};
worker.onerror = () => {
  setStatus('error', '⚠️ Solver failed to load — serve this page over http(s), not file://');
};

function setStatus(cls, text) {
  const el = $('solver-status');
  el.className = 'status-chip ' + cls;
  el.textContent = text;
}

// ---------------------------------------------------------------- palette UI
function buildPalette() {
  const bar = $('palette');
  bar.innerHTML = '';
  FACES.forEach((f, i) => {
    const sw = document.createElement('div');
    sw.className = 'swatch';
    sw.dataset.tool = i;
    sw.title = FACE_NAMES[f] + ' face color';
    sw.innerHTML =
      `<div class="chip"></div><span class="count"></span>` +
      `<button class="edit" title="Change this color to match your cube">✎</button>` +
      `<input type="color" value="${palette[i]}">`;
    sw.addEventListener('click', () => { selectedTool = i; refreshPalette(); });
    const input = sw.querySelector('input');
    sw.querySelector('.edit').addEventListener('click', (ev) => {
      ev.stopPropagation();
      input.click();
    });
    input.addEventListener('input', () => {
      palette[i] = input.value;
      refreshPalette();
      renderEditorNet();
    });
    bar.appendChild(sw);
  });
  const er = document.createElement('div');
  er.className = 'swatch eraser';
  er.dataset.tool = 'erase';
  er.title = 'Eraser';
  er.innerHTML = `<div class="chip"></div><span class="count">erase</span>`;
  er.addEventListener('click', () => { selectedTool = 'erase'; refreshPalette(); });
  bar.appendChild(er);
  refreshPalette();
}

function colorCounts() {
  const counts = Array(6).fill(0);
  FACES.forEach((f) => stickers[f].forEach((v) => { if (v >= 0) counts[v]++; }));
  return counts;
}

function refreshPalette() {
  const counts = colorCounts();
  document.querySelectorAll('#palette .swatch').forEach((sw) => {
    const tool = sw.dataset.tool;
    sw.classList.toggle('selected', String(selectedTool) === tool);
    if (tool !== 'erase') {
      const i = Number(tool);
      sw.querySelector('.chip').style.background = palette[i];
      sw.querySelector('input').value = palette[i];
      const cnt = sw.querySelector('.count');
      cnt.textContent = counts[i] + '/9';
      cnt.className = 'count' + (counts[i] === 9 ? ' full' : counts[i] > 9 ? ' over' : '');
    }
  });
}

// ---------------------------------------------------------------- net editor
function buildNetSkeleton(container, editable) {
  container.innerHTML = '';
  FACES.forEach((f) => {
    const face = document.createElement('div');
    face.className = 'face face-' + f;
    for (let i = 0; i < 9; i++) {
      const st = document.createElement('button');
      st.type = 'button';
      st.className = 'sticker' + (i === 4 ? ' center' : '');
      st.dataset.face = f;
      st.dataset.idx = i;
      if (i === 4) {
        st.textContent = f;
        st.title = FACE_NAMES[f] + ' center (fixed — edit the palette color instead)';
      } else if (editable) {
        st.addEventListener('click', () => paintSticker(f, i));
        st.addEventListener('contextmenu', (ev) => { ev.preventDefault(); eraseSticker(f, i); });
      }
      face.appendChild(st);
    }
    container.appendChild(face);
  });
}

function paintSticker(f, i) {
  if (selectedTool === 'erase') return eraseSticker(f, i);
  stickers[f][i] = selectedTool;
  onStateEdited();
}
function eraseSticker(f, i) {
  stickers[f][i] = -1;
  onStateEdited();
}
function onStateEdited() {
  renderEditorNet();
  refreshPalette();
  hideInputError();
}

function renderEditorNet() {
  paintNet($('net'), (f, i) => stickers[f][i]);
}

function paintNet(container, getIdx) {
  container.querySelectorAll('.sticker').forEach((st) => {
    const v = getIdx(st.dataset.face, Number(st.dataset.idx));
    if (v >= 0) {
      st.style.background = palette[v];
      st.classList.add('set');
    } else {
      st.style.background = '';
      st.classList.remove('set');
    }
  });
}

// ---------------------------------------------------------------- validation + solve
function faceletString() {
  return FACES.map((f) => stickers[f].map((v) => FACES[v]).join('')).join('');
}

function permutationParity(perm) {
  let inv = 0;
  for (let i = 0; i < perm.length; i++)
    for (let j = i + 1; j < perm.length; j++)
      if (perm[i] > perm[j]) inv++;
  return inv % 2;
}

function isPermutation(arr, n) {
  return arr.length === n && arr.slice().sort((a, b) => a - b).every((v, i) => v === i);
}

/** Returns an error message, or null if the cube is valid and solvable. */
function validateState() {
  let unset = 0;
  FACES.forEach((f) => stickers[f].forEach((v) => { if (v < 0) unset++; }));
  if (unset > 0) return `Not finished yet — ${unset} sticker${unset > 1 ? 's are' : ' is'} still blank.`;

  const counts = colorCounts();
  const bad = counts.map((c, i) => (c !== 9 ? `${FACE_NAMES[FACES[i]]}-center color: ${c}` : null)).filter(Boolean);
  if (bad.length) return 'Each color must appear exactly 9 times. Off: ' + bad.join(', ') + '.';

  const s = faceletString();
  let cube;
  try {
    cube = Cube.fromString(s);
  } catch (e) {
    return 'These colors don’t form a possible cube — please double-check them.';
  }
  if (cube.asString() !== s)
    return 'Impossible arrangement: at least one piece has a color combination that can’t exist on a real cube (e.g. two opposite colors on the same piece). Check the stickers.';

  const j = cube.toJSON();
  if (!isPermutation(j.cp, 8) || !isPermutation(j.ep, 12))
    return 'Impossible arrangement: the same piece appears twice. Check the stickers.';
  if (j.co.reduce((a, b) => a + b, 0) % 3 !== 0)
    return 'This cube can’t be solved: a corner is twisted in place. One corner’s colors are probably entered rotated — check the corners.';
  if (j.eo.reduce((a, b) => a + b, 0) % 2 !== 0)
    return 'This cube can’t be solved: an edge is flipped in place. One edge’s two colors are probably swapped — check the edges.';
  if (permutationParity(j.cp) !== permutationParity(j.ep))
    return 'This cube can’t be solved: two pieces are swapped. That can’t happen by normal turns — double-check the colors.';
  return null;
}

function updateSolveButton() {
  const btn = $('btn-solve');
  btn.disabled = !solverReady || solving;
  btn.textContent = solving ? '⏳ Solving…' : '🧠 Solve';
}

function solve() {
  hideInputError();
  const err = validateState();
  if (err) return showInputError(err);
  const s = faceletString();
  if (s === SOLVED) {
    hideSolutionPanel();
    return showInputError('This cube is already solved! 🎉', true);
  }
  solving = true;
  updateSolveButton();
  worker.postMessage({ type: 'solve', facelets: s });
}

function showInputError(msg, isInfo) {
  const el = $('input-error');
  el.textContent = msg;
  el.classList.remove('hidden');
  el.style.color = isInfo ? 'var(--ok)' : '';
}
function hideInputError() { $('input-error').classList.add('hidden'); }

// ---------------------------------------------------------------- solution playback
let playStates = [];   // facelet strings, length = moves + 1
let playMoves = [];    // move tokens
let playIdx = 0;
let playTimer = null;
let startPalette = []; // palette snapshot so later edits don't recolor the playback

function showSolution(solution) {
  const start = faceletString();
  playMoves = solution ? solution.split(/\s+/) : [];
  playStates = [start];
  const c = Cube.fromString(start);
  playMoves.forEach((m) => { c.move(m); playStates.push(c.asString()); });
  playIdx = 0;
  startPalette = palette.slice();
  stopPlay();

  $('solution-panel').classList.remove('hidden');
  $('move-count').textContent = playMoves.length + ' moves';
  const movesEl = $('moves');
  movesEl.innerHTML = '';
  playMoves.forEach((m) => {
    const chip = document.createElement('span');
    chip.className = 'move';
    chip.textContent = m;
    movesEl.appendChild(chip);
  });
  buildNetSkeleton($('playback-net'), false);
  renderPlayback();
  $('solution-panel').scrollIntoView({ behavior: 'smooth' });
}

function hideSolutionPanel() {
  stopPlay();
  $('solution-panel').classList.add('hidden');
}

function moveDescription(m) {
  const face = FACE_NAMES[m[0]];
  if (m.endsWith('2')) return `turn the ${face} face 180°`;
  if (m.endsWith("'")) return `turn the ${face} face counter-clockwise`;
  return `turn the ${face} face clockwise`;
}

function renderPlayback() {
  const state = playStates[playIdx];
  // color from the palette snapshot so later palette edits don't recolor history
  $('playback-net').querySelectorAll('.sticker').forEach((st) => {
    const letter = state[FACES.indexOf(st.dataset.face) * 9 + Number(st.dataset.idx)];
    st.style.background = startPalette[FACES.indexOf(letter)];
    st.classList.add('set');
  });
  document.querySelectorAll('#moves .move').forEach((chip, i) => {
    chip.classList.toggle('done', i < playIdx - 1);
    chip.classList.toggle('current', i === playIdx - 1);
  });
  const cap = $('playback-caption');
  if (playIdx === 0) {
    cap.textContent = 'Starting position — press Play or step through the moves.';
  } else if (playIdx === playMoves.length) {
    cap.textContent = `Move ${playIdx} of ${playMoves.length}: ${playMoves[playIdx - 1]} — ${moveDescription(playMoves[playIdx - 1])}. Solved! 🎉`;
  } else {
    cap.textContent = `Move ${playIdx} of ${playMoves.length}: ${playMoves[playIdx - 1]} — ${moveDescription(playMoves[playIdx - 1])}`;
  }
}

function stepPlayback(delta) {
  playIdx = Math.max(0, Math.min(playStates.length - 1, playIdx + delta));
  renderPlayback();
}

function stopPlay() {
  if (playTimer) clearInterval(playTimer);
  playTimer = null;
  $('btn-play').textContent = '▶ Play';
}

function togglePlay() {
  if (playTimer) return stopPlay();
  if (playIdx >= playStates.length - 1) playIdx = 0;
  $('btn-play').textContent = '⏸ Pause';
  renderPlayback();
  playTimer = setInterval(() => {
    if (playIdx >= playStates.length - 1) return stopPlay();
    stepPlayback(1);
  }, 900);
}

// ---------------------------------------------------------------- scramble / clear
function fillScramble() {
  const moves = "URFDLB";
  const suffix = ["", "'", "2"];
  const seq = [];
  let last = -1;
  for (let i = 0; i < 20; i++) {
    let f;
    do { f = Math.floor(Math.random() * 6); } while (f === last);
    last = f;
    seq.push(moves[f] + suffix[Math.floor(Math.random() * 3)]);
  }
  const c = new Cube();
  c.move(seq.join(' '));
  const s = c.asString();
  FACES.forEach((f, fi) => {
    for (let i = 0; i < 9; i++) stickers[f][i] = FACES.indexOf(s[fi * 9 + i]);
  });
  hideSolutionPanel();
  onStateEdited();
}

function clearStickers() {
  FACES.forEach((f, i) => {
    stickers[f] = Array(9).fill(-1);
    stickers[f][4] = i;
  });
  hideSolutionPanel();
  onStateEdited();
}

// ---------------------------------------------------------------- tabs
function showTab(name) {
  $('tab-scan').classList.toggle('active', name === 'scan');
  $('tab-manual').classList.toggle('active', name === 'manual');
  $('scan-panel').classList.toggle('hidden', name !== 'scan');
  $('manual-panel').classList.toggle('hidden', name !== 'manual');
  if (name !== 'scan') stopCamera();
}

// ---------------------------------------------------------------- scanning
const SCAN_ORDER = ['F', 'R', 'B', 'L', 'U', 'D'];
const SCAN_STEPS = {
  F: {
    title: 'Show any face — this becomes the FRONT',
    hint: 'Hold the cube level and fill the grid with the face. Your grip now defines the layout: keep track of which face is on top!',
  },
  R: {
    title: 'Rotate the cube 90° to the LEFT → scan the RIGHT face',
    hint: 'The front face swings to the left; keep the same face on top.',
  },
  B: {
    title: 'Rotate 90° LEFT again → scan the BACK face',
    hint: 'Keep the same face on top.',
  },
  L: {
    title: 'Rotate 90° LEFT again → scan the LEFT face',
    hint: 'Keep the same face on top.',
  },
  U: {
    title: 'Back to the front, then tilt the TOP toward the camera',
    hint: 'Rotate left once more so the original front faces the camera again, then tip the cube forward so the camera sees the TOP face. The original front face now points at the floor.',
  },
  D: {
    title: 'Tilt the BOTTOM toward the camera',
    hint: 'Back to the front position, then tip the cube backward so the camera sees the BOTTOM face. The original front face now points at the ceiling.',
  },
};

let stream = null;
let scanned = {};       // face letter -> [[r,g,b] x 9]
let scanPos = 0;        // index into SCAN_ORDER

async function startCamera() {
  const errEl = $('camera-error');
  errEl.classList.add('hidden');
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    errEl.textContent = 'Camera not available — this page must be served over HTTPS (or localhost). You can still use Manual input.';
    errEl.classList.remove('hidden');
    return;
  }
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'environment', width: { ideal: 1280 } },
      audio: false,
    });
  } catch (e) {
    errEl.textContent = 'Could not open the camera (' + e.name + '). Check the permission, or use Manual input.';
    errEl.classList.remove('hidden');
    return;
  }
  const video = $('video');
  video.srcObject = stream;
  $('scan-intro').classList.add('hidden');
  $('scan-live').classList.remove('hidden');
  scanned = {};
  scanPos = 0;
  updateScanUI();
  video.addEventListener('loadedmetadata', layoutOverlay);
  window.addEventListener('resize', layoutOverlay);
}

function stopCamera() {
  if (stream) {
    stream.getTracks().forEach((t) => t.stop());
    stream = null;
  }
  $('scan-live').classList.add('hidden');
  $('scan-intro').classList.remove('hidden');
}

const GRID_FRACTION = 0.62;

function layoutOverlay() {
  const video = $('video');
  const overlay = document.querySelector('.grid-overlay');
  const w = video.clientWidth, h = video.clientHeight;
  if (!w || !h) return;
  const side = Math.min(w, h) * GRID_FRACTION;
  overlay.style.width = side + 'px';
  overlay.style.height = side + 'px';
  overlay.style.left = (w - side) / 2 + 'px';
  overlay.style.top = (h - side) / 2 + 'px';
}

function updateScanUI() {
  const prog = $('scan-progress');
  prog.innerHTML = '';
  SCAN_ORDER.forEach((f, i) => {
    const dot = document.createElement('div');
    dot.className = 'dot' + (i < scanPos ? ' done' : i === scanPos ? ' current' : '');
    dot.textContent = f;
    dot.title = FACE_NAMES[f];
    prog.appendChild(dot);
  });
  const face = SCAN_ORDER[scanPos];
  if (face) {
    $('scan-instruction').textContent = `${scanPos + 1} / 6 — ${SCAN_STEPS[face].title}`;
    $('scan-hint').textContent = SCAN_STEPS[face].hint;
  }
  $('btn-retake').disabled = scanPos === 0;

  const thumbs = $('scan-thumbs');
  thumbs.innerHTML = '';
  SCAN_ORDER.slice(0, scanPos).forEach((f) => {
    const t = document.createElement('div');
    t.className = 'thumb';
    const mini = document.createElement('div');
    mini.className = 'mini';
    scanned[f].forEach(([r, g, b]) => {
      const cell = document.createElement('div');
      cell.style.background = `rgb(${r},${g},${b})`;
      mini.appendChild(cell);
    });
    t.appendChild(mini);
    const label = document.createElement('div');
    label.className = 'label';
    label.textContent = FACE_NAMES[f];
    t.appendChild(label);
    thumbs.appendChild(t);
  });
}

function captureFace() {
  const video = $('video');
  if (!video.videoWidth) return;
  const canvas = $('capture-canvas');
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(video, 0, 0);

  const side = Math.min(canvas.width, canvas.height) * GRID_FRACTION;
  const x0 = (canvas.width - side) / 2;
  const y0 = (canvas.height - side) / 2;
  const cell = side / 3;
  const patch = Math.max(4, Math.floor(cell * 0.36));

  const samples = [];
  for (let r = 0; r < 3; r++) {
    for (let c = 0; c < 3; c++) {
      const cx = Math.round(x0 + (c + 0.5) * cell - patch / 2);
      const cy = Math.round(y0 + (r + 0.5) * cell - patch / 2);
      const data = ctx.getImageData(cx, cy, patch, patch).data;
      let R = 0, G = 0, B = 0;
      const n = data.length / 4;
      for (let k = 0; k < data.length; k += 4) { R += data[k]; G += data[k + 1]; B += data[k + 2]; }
      samples.push([Math.round(R / n), Math.round(G / n), Math.round(B / n)]);
    }
  }
  scanned[SCAN_ORDER[scanPos]] = samples;
  scanPos++;
  if (scanPos >= SCAN_ORDER.length) return finishScan();
  updateScanUI();
}

function retakeLast() {
  if (scanPos === 0) return;
  scanPos--;
  delete scanned[SCAN_ORDER[scanPos]];
  updateScanUI();
}

function restartScan() {
  scanned = {};
  scanPos = 0;
  updateScanUI();
}

// --- color classification: nearest scanned center in CIELAB space ---
function rgbToLab([r, g, b]) {
  const lin = (v) => { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
  const [R, G, B] = [lin(r), lin(g), lin(b)];
  let x = (0.4124 * R + 0.3576 * G + 0.1805 * B) / 0.95047;
  let y = (0.2126 * R + 0.7152 * G + 0.0722 * B);
  let z = (0.0193 * R + 0.1192 * G + 0.9505 * B) / 1.08883;
  const f = (t) => (t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116);
  [x, y, z] = [f(x), f(y), f(z)];
  return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
}
const labDist = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
const rgbToHex = ([r, g, b]) => '#' + [r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('');

function finishScan() {
  // reference color per palette slot = the scanned center of that face
  const refs = FACES.map((f) => rgbToLab(scanned[f][4]));
  FACES.forEach((f) => {
    scanned[f].forEach((rgb, i) => {
      const lab = rgbToLab(rgb);
      let best = 0, bestD = Infinity;
      refs.forEach((ref, k) => {
        const d = labDist(lab, ref);
        if (d < bestD) { bestD = d; best = k; }
      });
      stickers[f][i] = i === 4 ? FACES.indexOf(f) : best;
    });
  });
  palette = FACES.map((f) => rgbToHex(scanned[f][4]));

  // warn if two centers are nearly identical (bad lighting / wrong faces shown)
  let tooClose = false;
  for (let a = 0; a < 6; a++)
    for (let b = a + 1; b < 6; b++)
      if (labDist(refs[a], refs[b]) < 12) tooClose = true;

  stopCamera();
  hideSolutionPanel();
  showTab('manual');
  onStateEdited();
  showInputError(
    tooClose
      ? '⚠️ Two of the scanned centers look almost identical — detection may be unreliable. Please check the stickers below carefully (tap to fix), then press Solve.'
      : 'Scan complete! Check the detected colors below — tap any sticker to fix it — then press Solve.',
    !tooClose
  );
}

// ---------------------------------------------------------------- wire up
buildPalette();
buildNetSkeleton($('net'), true);
renderEditorNet();
updateSolveButton();

$('tab-scan').addEventListener('click', () => showTab('scan'));
$('tab-manual').addEventListener('click', () => showTab('manual'));

$('btn-start-camera').addEventListener('click', startCamera);
$('btn-capture').addEventListener('click', captureFace);
$('btn-retake').addEventListener('click', retakeLast);
$('btn-restart-scan').addEventListener('click', restartScan);

$('btn-solve').addEventListener('click', solve);
$('btn-scramble').addEventListener('click', fillScramble);
$('btn-clear').addEventListener('click', clearStickers);

$('btn-first').addEventListener('click', () => { stopPlay(); playIdx = 0; renderPlayback(); });
$('btn-prev').addEventListener('click', () => { stopPlay(); stepPlayback(-1); });
$('btn-next').addEventListener('click', () => { stopPlay(); stepPlayback(1); });
$('btn-play').addEventListener('click', togglePlay);
$('btn-copy').addEventListener('click', async () => {
  try {
    await navigator.clipboard.writeText(playMoves.join(' '));
    $('btn-copy').textContent = '✓ Copied';
    setTimeout(() => { $('btn-copy').textContent = '📋 Copy'; }, 1500);
  } catch (e) { /* clipboard unavailable */ }
});
