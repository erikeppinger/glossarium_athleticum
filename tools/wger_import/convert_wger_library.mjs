// One-time conversion script: pulls the open, CC-BY-SA-licensed exercise
// database from wger.de (https://wger.de/api/v2/exerciseinfo/, no auth
// needed) and writes it out as templates/wger_starter_library.csv, in the
// exact column shape lib/import/exercise_spreadsheet_parser.dart already
// expects. Not shipped with the app - run manually, occasionally, to
// refresh the snapshot. See docs/THIRD_PARTY_LICENSES.md for the license
// this data carries once bundled.
//
// Usage: node tools/wger_import/convert_wger_library.mjs

const API_BASE = 'https://wger.de/api/v2/exerciseinfo/';
const PAGE_SIZE = 100;
const ENGLISH_LANGUAGE_ID = 2;
const OUTPUT_PATH = new URL('../../templates/wger_starter_library.csv', import.meta.url);
const AUTHOR_VALUE = 'wger.de (CC BY-SA)';

const HEADER = [
  'Exercise Name',
  'Category',
  'Movement Pattern',
  'Muscle Group(s)',
  'Equipment',
  'Difficulty',
  'Measurement Type',
  'Description / Cues',
  'Safety Notes',
  'Video Reference',
  'Embedding',
  'Author',
];

function stripHtml(html) {
  if (!html) return '';
  return html
    .replace(/<\/(p|li|ul|ol)>/gi, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/\n{2,}/g, '\n')
    .trim();
}

// RFC4180-ish: quote a field only when it needs it, doubling embedded quotes.
function csvField(value) {
  const s = String(value ?? '');
  if (/[",\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function csvRow(fields) {
  return fields.map(csvField).join(',');
}

function mapEquipment(equipmentList) {
  const names = equipmentList
    .map((e) => e.name.trim())
    .filter((n) => n.length > 0 && !/^none\b/i.test(n));
  if (names.length === 0) return 'None (Bodyweight)';
  return names.join(' & ');
}

function mapMuscleGroups(exercise) {
  const names = [...exercise.muscles, ...exercise.muscles_secondary]
    .map((m) => (m.name_en || '').trim())
    .filter((n) => n.length > 0);
  return [...new Set(names)].join(', ');
}

function mapMeasurementType(categoryName) {
  return categoryName === 'Cardio' ? 'Time' : 'Weight x Reps';
}

async function fetchAllExercises() {
  const results = [];
  let url = `${API_BASE}?limit=${PAGE_SIZE}&offset=0&format=json`;
  let pageCount = 0;
  while (url) {
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`wger API request failed: ${res.status} ${res.statusText} (${url})`);
    }
    const data = await res.json();
    results.push(...data.results);
    pageCount++;
    process.stdout.write(`\rFetched page ${pageCount} (${results.length}/${data.count})`);
    url = data.next;
  }
  process.stdout.write('\n');
  return results;
}

async function main() {
  console.log(`Fetching exercise data from ${API_BASE} ...`);
  const exercises = await fetchAllExercises();

  const rows = [];
  let skippedNoEnglish = 0;
  let skippedNoName = 0;

  for (const exercise of exercises) {
    const translation = exercise.translations.find((t) => t.language === ENGLISH_LANGUAGE_ID);
    if (!translation) {
      skippedNoEnglish++;
      continue;
    }
    const name = (translation.name || '').trim();
    if (!name) {
      skippedNoName++;
      continue;
    }

    const categoryName = exercise.category?.name || '';
    const video = exercise.videos?.find((v) => v.video)?.video || '';
    // The app bundles no images, but wger's own page for the exercise often
    // has pictures - the description ends with a link to it (tappable in
    // the exercise detail screen).
    const description = [
      stripHtml(translation.description),
      `On wger.de: https://wger.de/en/exercise/${exercise.id}/view-base`,
    ]
      .filter((part) => part.length > 0)
      .join('\n');

    rows.push([
      name,
      categoryName,
      '', // Movement Pattern - no wger equivalent
      mapMuscleGroups(exercise),
      mapEquipment(exercise.equipment || []),
      'Intermediate', // Difficulty - wger has no signal at all; see docs/THIRD_PARTY_LICENSES.md
      mapMeasurementType(categoryName),
      description,
      '', // Safety Notes - no wger equivalent
      video,
      '', // Embedding - always off; wger videos aren't YouTube anyway
      AUTHOR_VALUE,
    ]);
  }

  const csv = [csvRow(HEADER), ...rows.map(csvRow)].join('\r\n') + '\r\n';
  const fs = await import('node:fs');
  fs.writeFileSync(OUTPUT_PATH, csv, 'utf8');

  console.log(`\nWrote ${rows.length} exercises to ${OUTPUT_PATH.pathname.replace(/^\/([A-Za-z]:)/, '$1')}`);
  console.log(`Skipped ${skippedNoEnglish} exercise(s) with no English translation.`);
  console.log(`Skipped ${skippedNoName} exercise(s) with an empty English name.`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
