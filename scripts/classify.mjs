/**
 * classify.mjs — pure classification of mutation survivors.
 *
 * Two-stage pipeline:
 *   identifyProbeCandidates — finds drop-assert survivor groups sharing an abort code (pure)
 *   finalizeEvidence — stamps evidence only when jointKilled is measured true (pure)
 *
 * The gate runs the actual joint mutant between the two stages.
 * The gate NEVER reads expected.json, keys, or any answer file.
 */

function normFile(f) {
  const s = f.replace(/\\/g, '/');
  const i = s.search(/(sources|tests)\//);
  return i >= 0 ? s.slice(i) : s;
}

/**
 * Stage 1: identify groups of drop-assert survivors sharing the same abort code in the same file.
 * These are CANDIDATES for the mutual-redundancy probe — not yet evidence.
 *
 * @returns {{ candidates: Array<{code, file, lines: number[]}>, survivorDetails: Array }}
 */
export function identifyProbeCandidates(allResults, allAsserts) {
  const survived = allResults.filter(r => !r.killed);
  if (survived.length === 0) return { candidates: [], survivorDetails: survived };

  const dropSurvivors = survived.filter(s => s.mutation === 'drop-assert');

  const byFileAndCode = {};
  for (const s of dropSurvivors) {
    const assertAtLine = allAsserts.find(
      a => normFile(a.file) === normFile(s.file) && a.line === s.line
    );
    if (!assertAtLine) continue;
    const key = `${normFile(s.file)}::${assertAtLine.code}`;
    if (!byFileAndCode[key]) byFileAndCode[key] = [];
    byFileAndCode[key].push({ ...s, code: assertAtLine.code });
  }

  const candidates = [];
  for (const [, group] of Object.entries(byFileAndCode)) {
    if (group.length >= 2) {
      candidates.push({
        code: group[0].code,
        file: normFile(group[0].file),
        lines: group.map(g => g.line),
      });
    }
  }

  return { candidates, survivorDetails: survived };
}

/**
 * Stage 2: given probe outcomes (jointKilled per candidate), produce final reframed output.
 * Evidence is stamped ONLY when singles survive AND joint dies — measured, not pattern-matched.
 *
 * @param {Array} survived - all surviving mutant result objects
 * @param {Array<{code, file, lines, jointKilled: boolean|null}>} probeOutcomes
 * @returns {Array<{file, line, mutation, desc, original, evidence: string|null}>}
 */
export function finalizeEvidence(survived, probeOutcomes) {
  const confirmedLocs = new Set();
  for (const p of probeOutcomes) {
    if (p.jointKilled === true) {
      for (const ln of p.lines) confirmedLocs.add(`${p.file}:${ln}`);
    }
  }

  return survived.map(s => ({
    file: s.file,
    line: s.line,
    mutation: s.mutation,
    desc: s.desc,
    original: s.original,
    evidence: confirmedLocs.has(`${normFile(s.file)}:${s.line}`)
      ? 'mutual redundancy — each guard individually removable, jointly load-bearing → suspected-equivalent'
      : null,
  }));
}

/**
 * Convenience: both stages with pre-supplied joint outcomes (for selftest).
 */
export function classifySurvivors(allResults, allAsserts, jointOutcomes = null) {
  const { candidates, survivorDetails } = identifyProbeCandidates(allResults, allAsserts);

  const probeOutcomes = jointOutcomes
    ? candidates.map((c, i) => ({ ...c, jointKilled: jointOutcomes[i] ?? null }))
    : candidates.map(c => ({ ...c, jointKilled: null }));

  const reframed = finalizeEvidence(survivorDetails, probeOutcomes);
  return { reframed, probeOutcomes };
}
