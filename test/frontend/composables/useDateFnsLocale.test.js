import { describe, it, expect, vi, afterEach } from 'vitest'
import { loadDateFnsLocale } from '../../../app/frontend/composables/useDateFnsLocale.js'

describe('loadDateFnsLocale', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('returns null when code is blank or nullish', async () => {
    expect(await loadDateFnsLocale(null)).toBeNull()
    expect(await loadDateFnsLocale('')).toBeNull()
    expect(await loadDateFnsLocale(undefined)).toBeNull()
  })

  it('loads a known locale module and returns its default export', async () => {
    const nl = await loadDateFnsLocale('nl')
    expect(nl).not.toBeNull()
    // date-fns Locale objects expose a `code` property
    expect(nl.code).toBe('nl')
  })

  it('loads a region-qualified locale (en-US)', async () => {
    const enUS = await loadDateFnsLocale('en-US')
    expect(enUS).not.toBeNull()
    expect(enUS.code).toBe('en-US')
  })

  it('loads be-tarask (6-char subtag)', async () => {
    const beTarask = await loadDateFnsLocale('be-tarask')
    expect(beTarask).not.toBeNull()
    expect(beTarask.code).toBe('be-tarask')
  })

  it('rejects codes that fail the naming-convention check', async () => {
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // Path-traversal-style input should never reach the loader
    expect(await loadDateFnsLocale('../etc/passwd')).toBeNull()
    expect(await loadDateFnsLocale('not a locale')).toBeNull()
    expect(await loadDateFnsLocale('en_US')).toBeNull() // underscore, not hyphen

    const invalidErrors = errorSpy.mock.calls.filter(([msg]) => /invalid locale/i.test(String(msg)))
    expect(invalidErrors.length).toBe(3)
  })

  it('returns null for "cdn" even though it passes the pattern (file excluded from bundle)', async () => {
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    expect(await loadDateFnsLocale('cdn')).toBeNull()

    const unknownErrors = errorSpy.mock.calls.filter(([msg]) => /unknown locale/i.test(String(msg)))
    expect(unknownErrors.length).toBe(1)
  })

  it('logs and returns null for codes that pass the pattern but are not bundled', async () => {
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    expect(await loadDateFnsLocale('xx-ZZ')).toBeNull()

    const unknownErrors = errorSpy.mock.calls.filter(([msg]) => /unknown locale/i.test(String(msg)))
    expect(unknownErrors.length).toBe(1)
  })
})
