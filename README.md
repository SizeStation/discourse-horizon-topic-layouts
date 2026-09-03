# Horizon Topic Layouts

A Discourse theme component that adds selectable topic-list layouts for Horizon.

## Selector architecture

The selector foundation is split into four responsibilities:

- `lib/topic-layouts.js` defines the supported layout IDs, labels, and icons.
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

The current fallback order is user preference, then the global theme setting. Per-category defaults and restrictions will extend the service resolution step.

## Development

Install this nested theme component's dependencies independently from the main Discourse workspace:

```sh
pnpm install --ignore-workspace --frozen-lockfile
pnpm lint
```
