# Subtle's website

Static files, no build step: https://subtle.syncster.dev (Netlify, the site id
is in `../packaging/publish.env`). `downloads.json` is the release feed that
`tools/publish.sh` writes; the download buttons read it.

Deploy as it is: `tools/publish.sh --website-only`. Preview: `python3 -m http.server -d website`.
