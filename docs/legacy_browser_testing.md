# Legacy browser testing

The player runs on signage hardware whose browsers are frozen at whatever
shipped with the panel. Two bugs came from that and both got through CI:

- **#1927** — LG WebOS on Chrome 53. No ES modules at all, so it needs the
  `<script nomodule>` SystemJS bundle.
- **#1967** — LG WebOS on Chrome 79. It *has* ES modules, so it skipped the
  `nomodule` tags, loaded the modern bundle, and died on the
  `import.meta.resolve` guard `@vitejs/plugin-legacy` puts at the top of it.

Both were **bundle-selection** failures, not JavaScript incompatibilities. The
legacy bundle worked fine in Chrome 79 when loaded by hand; nothing on the page
told the browser to load it.

That distinction is why the existing guards all stayed green:

| Guard | What it checks | Why it missed #1967 |
| --- | --- | --- |
| `LegacyPlayerBundleTest` | built chunks parse at ES2016, SystemJS format, `cspHashes` drift | the bundles were fine |
| `LegacyPlayerTest` | SystemJS bundle boots and mounts | replays the bootstrap by hand, so the browser never chooses |
| `Frontend::PlayerControllerTest` | the bootstrap tags are in the HTML | asserts markup, not what a browser does with it |

A syntax check cannot close this gap either: `import.meta.resolve` is an API, not
syntax, so every legacy chunk parses cleanly at any `ecmaVersion`.

## The Legacy Browsers workflow

`.github/workflows/legacy-browsers.yml` loads the real player page in period
browsers and lets each one pick its own bundle. It runs on `workflow_dispatch`
and on pull requests touching the player or its Rails plumbing.

It is **advisory on purpose**. Path-filtered jobs never report a status on PRs
that skip them, so marking this a required check would hang every PR that does
not touch the frontend.

The path filter deliberately covers the Rails side (`app/helpers/frontend/**`
and friends). #1967 lived in `player_helper.rb` and changed nothing under
`app/frontend/`, so a filter scoped to the Vue code alone would have skipped the
job on the very PR that introduced the bug.

Only the player tests run. `ApplicationController` sets
`allow_browser versions: :modern`, so every admin page returns 406 in these
browsers by design.

## Where the old browsers come from

Docker Hub still hosts the Selenium 2/3-era images, tagged by build date and
element codename back to 2015. Each pinned whatever browser was current the day
it was built, which is the only practical source of period builds — the
version-numbered `selenium/standalone-*` tags stop at Chrome 95 and Firefox 137.

| Image | Browser | Driver |
| --- | --- | --- |
| `selenium/standalone-chrome:3.141.59-zinc` | Chrome 79.0.3945.117 | ChromeDriver 79 |
| `selenium/standalone-firefox:3.141.59-20210310` | Firefox 84.0.1 | geckodriver 0.29.0 |

Chrome 79.0.3945.117 is effectively the WebOS build from #1967, which reports
79.0.3945.79. Firefox 84 matters for the same reason Chrome 79 does: Firefox did
not ship `import.meta.resolve` until 106, so everything from Firefox 69 (our
floor) to 105 sits in the same gap, on a second engine.

Note the tags are not monotonic — the `20210310` image carries an *older*
Firefox (84.0.1) than `20210128` (85.0). Check what is actually inside an image
rather than inferring from its date:

```shell
docker run --rm --entrypoint="" selenium/standalone-firefox:3.141.59-20210310 \
  bash -c 'firefox --version; geckodriver --version | head -1'
```

## What we cannot reach, and why

Both floors in `allow_browser` are below what the harness can drive:

- **Chrome 53** — `selenium/standalone-chrome:2.53.1-americium` has exactly
  Chrome 53.0.2785.143, but its ChromeDriver 2.24 predates W3C and speaks only
  the JSON Wire Protocol, which `selenium-webdriver` 4.x dropped. Session
  creation returns a 500. Reaching it needs a pinned old client or raw CDP.
- **Firefox 69** — `selenium/standalone-firefox:3.141.59-uranium` has Firefox
  69.0, and a raw `POST /session` against the grid works, so the container is
  fine. The Selenium 4 client sends capabilities geckodriver 0.24 rejects. The
  cutoff is geckodriver 0.29.0 (Firefox 84 in this archive); 0.28.0 fails.

So the declared floors stay untested. Chrome 79 and Firefox 84 are stand-ins for
the class of bug that actually bit us, not proof the floors work.

## Running it locally

The images are ~1.2GB. `--network host` puts the grid and the Capybara server on
the same localhost, which avoids wiring up container networking:

```shell
docker run -d --name selenium --network host --shm-size=2g \
  selenium/standalone-chrome:3.141.59-zinc

RAILS_ENV=test bin/rake assets:precompile
RAILS_ENV=test bin/rails db:test:prepare

CAPYBARA_SERVER_PORT=45678 \
CAPYBARA_APP_HOST=127.0.0.1 \
SELENIUM_URL=http://localhost:4444/wd/hub \
SELENIUM_BROWSER=chrome \
  bin/rails test test/system/player_boot_test.rb

docker rm -f selenium
```

Swap in the Firefox image and `SELENIUM_BROWSER=firefox` for the other leg.
`--shm-size=2g` is not optional; these images crash tabs on the 64MB default.

### Environment variables

`test/application_system_test_case.rb` reads four, so one harness serves the
local runner, the devcontainer, and this workflow:

| Variable | Purpose |
| --- | --- |
| `CAPYBARA_SERVER_PORT` | presence switches the suite to a remote grid |
| `CAPYBARA_APP_HOST` | host the *browser* uses to reach the app (default `rails-app`, for the devcontainer) |
| `SELENIUM_URL` | full grid URL; Selenium 3 needs the `/wd/hub` suffix, Selenium 4 does not |
| `SELENIUM_BROWSER` | `chrome` (default) or `firefox` |

## The assertion that matters

`test/system/player_boot_test.rb` visits the page, waits for Vue to mount, and
then requires that every severe console entry be one plugin-legacy threw on
purpose.

That caveat is load-bearing. On a browser in the gap, a **correctly configured**
player logs two `SEVERE` errors — one from the detector probe, one from the
guard atop the modern chunk — and plugin-legacy's own fallback then logs
`"syntax error above and the same error below should be ignored"`. A naive
"no console errors" assertion fails on the working configuration.

`IGNORED_CONSOLE_ERRORS` names the two substrings that are expected today:

- `import.meta.resolve not supported` — plugin-legacy's deliberate throws.
- `Cannot resize text: zero dimension detected.` — `useTextResize` bails through
  `console.error` when the field has not been laid out yet, which happens on
  mount in every browser we tested. Pre-existing and harmless; drop the entry
  once it is downgraded to a warning.

Two implementation details are easy to get wrong and were both hit while
building this:

- Chrome's log buffer belongs to the **browser process**, not the Capybara
  session, so `Capybara.reset_sessions!` does not clear it and errors from
  earlier test files leak in. The test drains the buffer before visiting.
- The buffer is drained by reading it, so `severe_browser_logs` is destructive —
  call it once and keep the result.

Browser log capture is Chrome-only; `severe_browser_logs` returns `[]` under
geckodriver, where the mount assertion still applies.

### Verifying the harness has teeth

Both legs were confirmed to fail when the fix is removed. Delete the detector
and fallback tags from `Frontend::PlayerHelper#vite_legacy_player_tags` and
`PlayerBootTest` fails on Chrome 79 and Firefox 84 with
`expected to find css "#screen .screen #background"`, while the modern-Chrome
suite stays green. Worth re-running after any change to how the bundles are
selected.
