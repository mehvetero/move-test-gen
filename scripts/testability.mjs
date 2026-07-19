/**
 * testability.mjs — pre-flight check for module testability.
 *
 * Scans a Move module and warns if it defines structs that have no
 * #[test_only] constructor or public constructor. If abort paths require
 * objects that can't be created in tests, the module is untestable.
 *
 * Pure function, no I/O beyond reading the file content passed in.
 */

/**
 * Check if a module's key structs are constructible in tests.
 *
 * @param {string} source - file content of a .move source file
 * @param {string} moduleName - module name for reporting
 * @returns {{ testable: boolean, warnings: string[] }}
 */
export function checkTestability(source, moduleName) {
  const warnings = [];

  // find all struct names
  const structNames = [];
  for (const m of source.matchAll(/public\s+struct\s+(\w+)/g)) {
    structNames.push(m[1]);
  }

  if (structNames.length === 0) return { testable: true, warnings };

  // find all functions that return these structs (constructors)
  const constructors = new Set();
  // public fun ... : StructName
  for (const m of source.matchAll(/(?:public|#\[test_only\][\s\S]*?public)\s+fun\s+\w+[^)]*\)(?:\s*:\s*([^{]+))?/g)) {
    if (m[1]) {
      for (const s of structNames) {
        if (m[1].includes(s)) constructors.add(s);
      }
    }
  }

  // simpler: look for test_only functions that mention struct names
  const testOnlyBlocks = source.match(/#\[test_only\][\s\S]*?(?=\n\s*(?:public|fun|#\[))/g) || [];
  for (const block of testOnlyBlocks) {
    for (const s of structNames) {
      if (block.includes(s)) constructors.add(s);
    }
  }

  // also check: fun new / fun create / fun empty that return struct
  for (const m of source.matchAll(/(?:public\s+)?fun\s+(\w*(?:new|create|empty|init)\w*)[^{]*?:\s*(\w+)/g)) {
    if (structNames.includes(m[2])) constructors.add(m[2]);
  }

  // structs with no constructor found
  const unconstructible = structNames.filter(s => !constructors.has(s));

  // check if any public function takes these unconstructible types as params
  const publicFns = [...source.matchAll(/public\s+fun\s+(\w+)\(([^)]*)\)/g)];
  for (const [, fnName, params] of publicFns) {
    for (const s of unconstructible) {
      if (params.includes(s) && !params.includes(`&${s}`) && fnName !== 'destroy' && !fnName.includes('testing')) {
        warnings.push(`${moduleName}::${fnName} takes ${s} but no test constructor found for ${s}`);
      }
    }
  }

  // check specifically for CoinMetadata pattern (farm's problem)
  if (source.includes('CoinMetadata') && !source.includes('test_only')) {
    warnings.push(`${moduleName} uses CoinMetadata but has no #[test_only] helpers — abort paths behind CoinMetadata are likely untestable`);
  }

  const testable = warnings.length === 0;
  return { testable, warnings };
}
