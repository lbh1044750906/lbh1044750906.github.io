# Academic Homepage Redesign — Design Doc

**Date:** 2026-06-29
**Author:** Bohao Li (with Claude)
**Status:** Implemented
**Scope:** Visual + structural redesign of personal homepage (still using GitHub Pages-friendly static HTML).

## Background

The previous homepage was based on the popular Hong Kong CS PhD "mmistakes" template
(Bootstrap + Newsmreader + Kanit, large blue banner + anime avatar, markdown-loaded
content sections). While functional, it felt too casual for an academic profile and
lacked the layout conventions of typical PhD/researcher pages.

## Goals

1. Adopt a **clean academic / minimalist** visual style typical of CS PhD
   personal pages (e.g. al-folio-inspired, with sticky sidebar profile + main
   content).
2. Replace the cartoonish visual elements (large background banner, anime avatar,
   emoji section icons) with conservative choices.
3. Introduce **card-style** presentation for *Publications* and *News*, which
   benefit from richer visual structure than a flat list.
4. Keep the existing **Markdown + YAML content loading** pipeline so that
   ongoing content edits do not require touching HTML.

## Non-Goals

- No dark mode toggle.
- No blog / RSS feed.
- No multilingual switch (English only).
- No JS framework migration — vanilla JS + marked.js + js-yaml is retained.

## Decisions

### Layout

- **Two-column layout** with sticky left sidebar (240 px) and fluid main content
  (`max-width: 1080 px`, centered).
- Sidebar contains: avatar, name (EN + CN), role, affiliation, tagline, contact
  list, section navigation.
- Main content contains: *About*, *News*, *Publications*, *Awards*, footer.
- On screens < 820 px the columns collapse to a single column with the sidebar
  pushed above as a centered header.

### Type System

| Element | Family | Notes |
|---|---|---|
| Headings (section titles, names, pub titles) | EB Garamond (serif) | Falls back through Noto Serif SC → Songti SC → Georgia |
| Body | Inter (sans) | Falls back through Noto Sans SC → PingFang SC |
| Code | JetBrains Mono / ui-monospace | Inline only |

### Color Palette

| Token | Value | Use |
|---|---|---|
| `--text` | `#1a1a1a` | Headings, primary copy |
| `--text-soft` | `#4a4a4a` | Sidebar contact lines |
| `--text-mute` | `#888` | Dates, captions, dividers |
| `--border` | `#e8e8e8` | Card borders, separators, avatar edges |
| `--border-strong` | `#d4d4d4` | Card left-edge marker (default state) |
| `--accent` | `#1f4d3a` (deep green) | Tagline, link color, card hover marker, sidebar links on hover |
| `--bg-soft` | `#fafafa` | Code block backgrounds |

### Card Style

Both `.pub-card` and `.news-card` use:

- `1 px solid #e8e8e8` border with a stronger `3 px solid #d4d4d4` *left edge*
  marker that turns into the accent green on hover.
- `border-radius: 4px` (deliberately tiny — keeps the academic, almost-printed look).
- No drop shadow at rest; a very subtle `0 2px 10px rgba(0,0,0,0.04)` shadow on
  hover.
- On hover: `translateX(2px)` slide + left edge becomes accent green.
- Cards stack vertically with a 12-px gap.

### Removed / Not Used

- Bootstrap CSS (replaced with handwritten CSS)
- Bootstrap JS
- Bootstrap Icons (kept, but only used for the *tiny* sidebar contact icons; the
  full icon font is loaded)
- MathJax (`tex-svg.js` ~2 MB) and the heavier chart-style fonts
- Top banner background image and its overlay text
- Emoji section icons (📁 🎓 💼)

### Content Pipeline (unchanged)

- `index.html` contains only the page skeleton.
- `contents/*.md` holds Markdown text for each section.
- `contents/config.yml` holds template-display strings.
- `static/js/scripts.js` fetches YAML + MD on `DOMContentLoaded` and writes them
  into `data-config="…"` and `id="…-md"` slots.
- Uses `marked.js` (markdown → HTML) and `js-yaml` (config → JS object).

### Sections on the Page

1. **About** — short bio, education list, research interests, contact, hobbies.
2. **News** — newest at top, date on the left, one-line description on the right.
3. **Publications** — one card per paper, title (serif), authors (with **Bohao
   Li** highlighted), italic venue, year.
4. **Awards** — single clean list (entries are short; cards would feel noisy).

## File Changes Summary

| File | Action |
|---|---|
| `index.html` | Rewritten — new layout, new font links, removed Bootstrap |
| `static/css/main.css` | Rewritten — handwritten CSS implementing tokens + layouts above |
| `static/css/styles.css` | Untouched — no longer imported; safe to delete later |
| `static/js/scripts.js` | Updated — added `news` to sections; supports `data-config="…"` attributes |
| `static/js/marked.min.js` | Untouched |
| `static/js/js-yaml.min.js` | Untouched |
| `contents/home.md` | Rewritten — restructured About block |
| `contents/news.md` | **New** — placeholder card-based news entries |
| `contents/publications.md` | Rewritten — explicit HTML cards instead of plain bullets |
| `contents/awards.md` | Translated to English + cleaner formatting |
| `contents/experience.md` | Untouched (still empty) — section intentionally removed from navbar |
| `contents/config.yml` | Trimmed to only the keys actually displayed |

## Preview

```bash
cd "D:/IIE Projects/1-个人成果/5-个人主页/lbh1044750906.github.io-main"
python -m http.server 8000
# open http://localhost:8000 in the browser
```

Or simply double-click `index.html` — modern browsers can serve it from
`file://` *but* `fetch()` of `contents/*.md` is blocked under
`file://` in Chrome, so the server route is the reliable option.

## Verification

- ✅ All resources return `200` on the local server (`index.html`, `main.css`,
  `scripts.js`, `*.md`, `config.yml`, `personal_photo.jpg`).
- ✅ Browser renders sidebar + content without horizontal scrollbars at
  ≥ 820 px.
- ✅ News cards show newest-first with the date column on the left.

## Future Work (Not Done)

- Remove `static/css/styles.css` and `static/js/bootstrap.bundle.min.js`,
  `static/js/tex-svg.js` to slim the repo (kept for now, no longer referenced).
- Add a dark-mode toggle (would need CSS variables only — straightforward).
- Add a real Google Scholar / ORCID / DBLP link once those profiles exist.
