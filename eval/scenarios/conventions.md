# scenario conventions

- one dir per scenario: `NN-trap-name/` with `sources/`, `tests/` (EMPTY in git —
  the skill's homework), `Move.toml` (rev pinned to the CLI you run), `expected.json`.
- `expected.json` holds the scenario's ground truth the runner sanity-checks every
  round: at minimum `{"asserts": N}` — if the gate ever reads a different count,
  the sources drifted and the round aborts.
- generation is fired ONLY via eval/prompt.template (or prompt-varied.template on
  a sweep round). Fill placeholders; never re-compose. (T71.)
- rounds are recorded by eval/run.mjs into eval/results/<scenario>/ — dated
  records; never edit figures by hand.
