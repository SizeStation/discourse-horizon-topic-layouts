# Horizon Topic Layouts

A Discourse theme component that adds selectable topic-list layouts for Horizon.

## Selector architecture

The selector foundation is split into five responsibilities:

- `lib/topic-layouts.js` defines the supported layout IDs, labels, and icons.
- `lib/topic-layout-config.js` resolves category defaults and available layouts.
- `lib/topic-layout-preferences.js` creates context-specific storage keys and safely reads and writes `localStorage`.
- `services/horizon-topic-layout-preferences.js` resolves the active layout and applies its document class.
- `components/topic-layout-selector.gjs` renders the `DMenu` control and handles selection and reset actions.

Preferences are stored separately for each user and browsing context. Categories use `category:<id>` contexts; Latest, New, Unread, and Top use `filter:<name>` contexts.

The active layout adds one of these classes to the document root:

```text
horizon-topic-layouts--comfortable
horizon-topic-layouts--compact
horizon-topic-layouts--minimal
horizon-topic-layouts--media-list
horizon-topic-layouts--gallery
horizon-topic-layouts--masonry
```

Layout styles should scope themselves through these classes without replacing core or Horizon topic-list templates.

The fallback order is an allowed user preference, then the category default, then the global theme setting.

## Category configuration

Administrators can add Category layout rules through the component's theme settings. Each rule selects one category, its default layout, and layouts to hide through six flat boolean controls.

- Every layout is available when all Hide controls are off.
- A category default remains available even if its Hide control is on.
- A stored user preference is ignored while that layout is hidden.
- Categories without a configuration inherit the global default and expose every layout.
- If duplicate configurations target one category, the first configuration is used.

## Layout implementations

Comfortable deliberately adds no visual overrides and preserves Horizon's native high-context topic cards.

Compact restyles those existing cards without replacing their template. It keeps the creator avatar, title, shortened excerpt, category, up to three tags, status, activity time, and topic statistics while hiding verbose author text, assignment details, and reply wording. Wide viewports place category and tags above replies and activity in a stable metadata region; narrower viewports move that metadata into secondary rows.

Minimal presents topic data as flat, border-separated rows containing the title, up to three tags, replies, activity, and compact topic-status icons. Narrow viewports show one tag and move tags and activity to a second line. The supplementary Hot status is omitted.

Media list preserves the native high-context card content and adds a lazy-loaded topic thumbnail on the left. It requests a 320×240 optimized thumbnail, falls back to the original topic image while optimized thumbnails are generated, and displays a category-colored placeholder for topics without an image.

These modes assume Horizon's default `topic_card_high_context` setting remains enabled.

## Development

Install this nested theme component's dependencies independently from the main Discourse workspace:

```sh
pnpm install --ignore-workspace --frozen-lockfile
pnpm lint
```
