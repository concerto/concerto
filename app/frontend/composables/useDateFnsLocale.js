// Lazy-loaded date-fns locale modules, code-split per locale by Vite at build
// time. Each entry is `() => import('date-fns/locale/<code>.js')`.
//
// import.meta.glob needs a static, file-relative path; Vite does not resolve
// bare specifiers like `date-fns/locale/*.js` or root-absolute paths like
// `/node_modules/...` (see vitejs/vite#6370). Keeping this helper colocated
// with other composables means the brittle relative path lives in one
// purpose-built module rather than in every consumer.
// Exclude cdn.js, cdn.min.js, and types.js — non-locale files that ship in the
// same directory. All three would otherwise become unnecessary Vite lazy chunks.
const LOCALE_LOADERS = import.meta.glob([
  '../../../node_modules/date-fns/locale/*.js',
  '!../../../node_modules/date-fns/locale/cdn*.js',
  '!../../../node_modules/date-fns/locale/types.js',
])

// Locale codes are restricted to date-fns's naming convention (e.g. "nl",
// "en-US") to keep user input from reaching the dynamic import as an
// arbitrary path. The regex also rejects path-traversal attempts.
// Subtag allows up to 6 chars to cover "be-tarask" (Belarusian Taraškievica).
const LOCALE_CODE_PATTERN = /^[a-zA-Z]{2,3}(-[a-zA-Z]{2,6})?$/

/**
 * Dynamically loads a date-fns Locale module.
 *
 * Returns the Locale object, or null when the code is blank, fails the
 * naming-convention check, isn't bundled, or fails to load. In every
 * fallback case the error is reported to the console so a misconfigured
 * Clock surfaces in the player's devtools rather than silently rendering
 * in the default en-US locale.
 *
 * @param {string|null|undefined} code - date-fns locale code (e.g. "nl", "en-US")
 * @returns {Promise<object|null>}
 */
export async function loadDateFnsLocale(code) {
  if (!code) return null

  if (!LOCALE_CODE_PATTERN.test(code)) {
    console.error(`useDateFnsLocale: invalid locale code "${code}" — using default.`)
    return null
  }

  const loader = LOCALE_LOADERS[`../../../node_modules/date-fns/locale/${code}.js`]
  if (!loader) {
    console.error(`useDateFnsLocale: unknown locale "${code}" — using default.`)
    return null
  }

  try {
    const mod = await loader()
    return mod.default ?? null
  } catch (error) {
    console.error(`useDateFnsLocale: failed to load locale "${code}" — using default.`, error)
    return null
  }
}
