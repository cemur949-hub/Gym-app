// Web worker: initializes the Kociemba two-phase solver (a few seconds of
// table generation) off the main thread, then solves facelet strings on demand.
importScripts('lib/cube.js', 'lib/solve.js');

Cube.initSolver();
postMessage({ type: 'ready' });

onmessage = function (e) {
  if (e.data.type !== 'solve') return;
  try {
    var cube = Cube.fromString(e.data.facelets);
    var solution = cube.solve();
    postMessage({ type: 'solution', solution: solution });
  } catch (err) {
    postMessage({ type: 'error', message: String(err && err.message || err) });
  }
};
