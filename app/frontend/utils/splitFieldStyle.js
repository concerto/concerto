const boxModelPrefixes = [
  'border',
  'padding',
  'box-shadow',
  'outline',
];

/**
 * Splits a CSS style string into inheritable text styles and box-model styles.
 *
 * Field styles (color, font-family, background, etc.) stay on the outer field
 * container. Box-model styles (border, padding, etc.) are passed to content
 * components that can apply them to the appropriate element.
 *
 * @param {string} styleString - Raw CSS style string, e.g. "color:#000; border:1px solid #ccc;"
 * @returns {{ textStyle: string, boxStyle: string }}
 */
export function splitFieldStyle(styleString) {
  if (!styleString) {
    return { textStyle: '', boxStyle: '' };
  }

  const textParts = [];
  const boxParts = [];

  for (const segment of styleString.split(';')) {
    const trimmed = segment.trim();
    if (!trimmed) continue;

    const colonIndex = trimmed.indexOf(':');
    if (colonIndex === -1) continue;

    const property = trimmed.substring(0, colonIndex).trim().toLowerCase();

    if (boxModelPrefixes.some(prefix => property.startsWith(prefix))) {
      boxParts.push(trimmed);
    } else {
      textParts.push(trimmed);
    }
  }

  return {
    textStyle: textParts.length ? textParts.join('; ') + ';' : '',
    boxStyle: boxParts.length ? boxParts.join('; ') + ';' : '',
  };
}
