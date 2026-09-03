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

Compact restyles those existing cards without replacing their template. It keeps the creator avatar, title, category and tags, status, activity time, and topic statistics while hiding verbose author text, excerpts, assignment details, and reply wording. Metadata moves to a second row when the available width cannot support the single-row presentation.

Both modes assume Horizon's default `topic_card_high_context` setting remains enabled.

## Development

Install this nested theme component's dependencies independently from the main Discourse workspace:

```sh
pnpm install --ignore-workspace --frozen-lockfile
pnpm lint
```
