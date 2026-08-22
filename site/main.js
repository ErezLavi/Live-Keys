/* ChordLens landing page — download routing + a small playable chord-detection demo. */

const REPO = 'ErezLavi/ChordLens';
const RELEASES = `https://github.com/${REPO}/releases`;

/* ------------------------------------------------------------------ *
 * Downloads
 * ------------------------------------------------------------------ */

const PLATFORMS = {
  macos: { label: 'Download for macOS', file: 'ChordLens.dmg', icon: '' },
  windows: { label: 'Download for Windows', file: 'ChordLens-Setup.exe', icon: '⊞' },
  android: { label: 'Download for Android', file: 'app-release.apk', icon: '🤖' },
};

/** Direct "latest release" download URL — GitHub redirects it to the current tag. */
const latestUrl = (file) => `${RELEASES}/latest/download/${file}`;

function detectOS() {
  const ua = navigator.userAgent;
  const platform = navigator.platform || '';
  if (/Android/i.test(ua)) return 'android';
  if (/Win/i.test(platform) || /Windows/i.test(ua)) return 'windows';
  if (/Mac/i.test(platform) || /Mac OS X/i.test(ua)) {
    // iPadOS reports as a Mac but cannot run the desktop build.
    if (navigator.maxTouchPoints > 1) return null;
    return 'macos';
  }
  return null;
}

function setUpPrimaryCta() {
  const os = detectOS();
  const btn = document.getElementById('primary-download');
  const label = document.getElementById('primary-label');
  const sub = document.getElementById('primary-sub');
  const icon = document.getElementById('primary-icon');

  if (!os) {
    label.textContent = 'Download ChordLens';
    sub.textContent = 'macOS · Windows · Android';
    icon.textContent = '↓';
    btn.href = '#download';
    return os;
  }

  const p = PLATFORMS[os];
  label.textContent = p.label;
  sub.textContent = p.file;
  icon.textContent = p.icon;
  btn.href = latestUrl(p.file);

  const card = document.querySelector(`.dl[data-os="${os}"]`);
  if (card) card.classList.add('recommended');
  return os;
}

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(1)} MB`;

/** Enrich the page with live release metadata; the static links work regardless. */
async function loadRelease(os) {
  try {
    const res = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' },
    });
    if (!res.ok) return;
    const release = await res.json();
    const tag = release.tag_name || '';

    if (tag) {
      const pill = document.getElementById('version-pill');
      pill.textContent = `${tag} · free & open source`;
      pill.style.cursor = 'pointer';
      pill.onclick = () => window.open(release.html_url || RELEASES, '_blank', 'noopener');

      const date = release.published_at
        ? new Date(release.published_at).toLocaleDateString(undefined, {
            year: 'numeric', month: 'long', day: 'numeric',
          })
        : null;
      document.getElementById('release-sub').textContent =
        date ? `Latest release ${tag} — published ${date}.` : `Latest release ${tag}.`;

      if (os) document.getElementById('primary-sub').textContent = `${PLATFORMS[os].file} · ${tag}`;
    }

    for (const asset of release.assets || []) {
      const el = document.querySelector(`[data-size-for="${asset.name}"]`);
      if (el) el.textContent = formatSize(asset.size);
    }
  } catch {
    /* Offline or rate limited — the hard-coded latest links still work. */
  }
}

loadRelease(setUpPrimaryCta());

/* ------------------------------------------------------------------ *
 * Playable demo keyboard
 * ------------------------------------------------------------------ */

const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const START_MIDI = 60; // C4
const OCTAVES = 2;

/* Interval sets above the root, mirroring the app's chord database. */
const CHORD_DB = [
  ['', [4, 7]],
  ['m', [3, 7]],
  ['sus2', [2, 7]],
  ['sus4', [5, 7]],
  ['dim', [3, 6]],
  ['aug', [4, 8]],
  ['5', [7]],
  ['6', [4, 7, 9]],
  ['m6', [3, 7, 9]],
  ['7', [4, 7, 10]],
  ['maj7', [4, 7, 11]],
  ['m7', [3, 7, 10]],
  ['mMaj7', [3, 7, 11]],
  ['m7b5', [3, 6, 10]],
  ['dim7', [3, 6, 9]],
  ['7sus4', [5, 7, 10]],
  ['7#5', [4, 8, 10]],
  ['7b5', [4, 6, 10]],
  ['add9', [2, 4, 7]],
  ['madd9', [2, 3, 7]],
  ['9', [2, 4, 7, 10]],
  ['maj9', [2, 4, 7, 11]],
  ['m9', [2, 3, 7, 10]],
  ['6/9', [2, 4, 7, 9]],
  ['11', [2, 4, 5, 7, 10]],
  ['m11', [2, 3, 5, 7, 10]],
  ['13', [2, 4, 5, 7, 9, 10]],
];

const setKey = (intervals) => [...new Set(intervals)].sort((a, b) => a - b).join(',');
const CHORD_LOOKUP = new Map(CHORD_DB.map(([name, iv]) => [setKey(iv), name]));

/**
 * Names the chord formed by a set of MIDI notes. Roots are tried lowest-first so
 * root position wins, and an inversion is reported with its bass note.
 */
function detectChord(midiNotes) {
  const notes = [...midiNotes].sort((a, b) => a - b);
  if (notes.length < 2) return null;

  const pitchClasses = [...new Set(notes.map((n) => n % 12))];
  if (pitchClasses.length < 2) return null;

  const bass = notes[0] % 12;
  const candidates = [bass, ...pitchClasses.filter((pc) => pc !== bass)];

  for (const root of candidates) {
    const intervals = pitchClasses.filter((pc) => pc !== root).map((pc) => (pc - root + 12) % 12);
    const name = CHORD_LOOKUP.get(setKey(intervals));
    if (name === undefined) continue;
    const symbol = NOTE_NAMES[root] + name;
    return root === bass ? symbol : `${symbol}/${NOTE_NAMES[bass]}`;
  }
  return null;
}

/* --- audio --- */

let audioCtx = null;
const voices = new Map();

function noteFrequency(midi) {
  return 440 * Math.pow(2, (midi - 69) / 12);
}

function startNote(midi) {
  if (voices.has(midi)) return;
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === 'suspended') audioCtx.resume();

  const now = audioCtx.currentTime;
  const gain = audioCtx.createGain();
  gain.gain.setValueAtTime(0.0001, now);
  gain.gain.exponentialRampToValueAtTime(0.16, now + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.07, now + 0.5);
  gain.connect(audioCtx.destination);

  const osc = audioCtx.createOscillator();
  osc.type = 'triangle';
  osc.frequency.value = noteFrequency(midi);
  osc.connect(gain);
  osc.start(now);

  voices.set(midi, { osc, gain });
}

function stopNote(midi) {
  const voice = voices.get(midi);
  if (!voice) return;
  voices.delete(midi);
  const now = audioCtx.currentTime;
  voice.gain.gain.cancelScheduledValues(now);
  voice.gain.gain.setValueAtTime(Math.max(voice.gain.gain.value, 0.0001), now);
  voice.gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.25);
  voice.osc.stop(now + 0.3);
}

/* --- keyboard UI --- */

const piano = document.getElementById('piano');
const chordEl = document.getElementById('demo-chord');
const notesEl = document.getElementById('demo-notes');
const held = new Set();
const keyEls = new Map();

function buildKeyboard() {
  const whites = [];
  const blacks = [];

  for (let i = 0; i < OCTAVES * 12 + 1; i++) {
    const midi = START_MIDI + i;
    const name = NOTE_NAMES[midi % 12];
    const isBlack = name.includes('#');
    const el = document.createElement('button');
    el.type = 'button';
    el.className = `key ${isBlack ? 'black' : 'white'}`;
    el.dataset.midi = String(midi);
    el.setAttribute('aria-label', `${name}${Math.floor(midi / 12) - 1}`);
    if (!isBlack) el.textContent = `${name}${Math.floor(midi / 12) - 1}`;
    keyEls.set(midi, el);
    (isBlack ? blacks : whites).push(el);
  }

  whites.forEach((el) => piano.appendChild(el));
  blacks.forEach((el) => piano.appendChild(el));
  positionBlackKeys();
}

/** Black keys sit between their neighbouring white keys, measured after layout. */
function positionBlackKeys() {
  const pianoRect = piano.getBoundingClientRect();
  const whiteWidth = keyEls.get(START_MIDI).getBoundingClientRect().width;
  const width = whiteWidth * 0.58;

  for (const [midi, el] of keyEls) {
    if (!el.classList.contains('black')) continue;
    const left = keyEls.get(midi - 1);
    const right = keyEls.get(midi + 1);
    if (!left || !right) continue;
    const boundary = (left.getBoundingClientRect().right + right.getBoundingClientRect().left) / 2;
    el.style.width = `${width}px`;
    el.style.left = `${boundary - pianoRect.left - width / 2}px`;
  }
}

function press(midi) {
  if (held.has(midi)) return;
  held.add(midi);
  keyEls.get(midi)?.classList.add('on');
  startNote(midi);
  render();
}

function release(midi) {
  if (!held.delete(midi)) return;
  keyEls.get(midi)?.classList.remove('on');
  stopNote(midi);
  render();
}

function render() {
  const notes = [...held].sort((a, b) => a - b);
  if (notes.length === 0) {
    chordEl.textContent = '—';
    chordEl.classList.add('idle');
    notesEl.textContent = 'Play two or more notes';
    return;
  }
  notesEl.textContent = notes.map((m) => `${NOTE_NAMES[m % 12]}${Math.floor(m / 12) - 1}`).join('  ·  ');
  const chord = detectChord(notes);
  chordEl.textContent = chord ?? (notes.length === 1 ? NOTE_NAMES[notes[0] % 12] : '?');
  chordEl.classList.toggle('idle', chord === null);
}

/* --- pointer input --- */

function midiFromEvent(e) {
  const el = document.elementFromPoint(e.clientX, e.clientY);
  const key = el?.closest?.('.key');
  return key ? Number(key.dataset.midi) : null;
}

let pointerDown = false;
let glided = null;

piano.addEventListener('pointerdown', (e) => {
  e.preventDefault();
  pointerDown = true;
  glided = midiFromEvent(e);
  if (glided !== null) press(glided);
});

piano.addEventListener('pointermove', (e) => {
  if (!pointerDown) return;
  const midi = midiFromEvent(e);
  if (midi === glided) return;
  if (glided !== null) release(glided);
  glided = midi;
  if (midi !== null) press(midi);
});

const endPointer = () => {
  pointerDown = false;
  if (glided !== null) release(glided);
  glided = null;
};
window.addEventListener('pointerup', endPointer);
window.addEventListener('pointercancel', endPointer);

/* --- computer keyboard, same mapping as the app --- */

const KEY_OFFSETS = {
  z: 0, s: 1, x: 2, d: 3, c: 4, v: 5, g: 6, b: 7, h: 8,
  n: 9, j: 10, m: 11, ',': 12, l: 13, '.': 14, ';': 15, '/': 16,
};

let octaveShift = 0;

window.addEventListener('keydown', (e) => {
  if (e.metaKey || e.ctrlKey || e.altKey || e.repeat) return;
  const key = e.key.toLowerCase();
  if (key === '[') { octaveShift = Math.max(octaveShift - 1, -1); return; }
  if (key === ']') { octaveShift = Math.min(octaveShift + 1, 1); return; }
  const offset = KEY_OFFSETS[key];
  if (offset === undefined) return;
  e.preventDefault();
  press(START_MIDI + offset + octaveShift * 12);
});

window.addEventListener('keyup', (e) => {
  const offset = KEY_OFFSETS[e.key.toLowerCase()];
  if (offset === undefined) return;
  // Release every octave copy so a shift mid-press cannot strand a note.
  for (const shift of [-1, 0, 1]) release(START_MIDI + offset + shift * 12);
});

buildKeyboard();
window.addEventListener('resize', positionBlackKeys);
