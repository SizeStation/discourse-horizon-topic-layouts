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

Minimal presents topic data as flat, border-separated rows containing the title, up to three tags, replies, activity, and compact topic-status icons. Narrow viewports keep the title on the first line and show up to three tags below it, with replies immediately before the activity timestamp on the right. Long tags truncate to fit the available space. The supplementary Hot status is omitted.

Media list preserves the native high-context card content and adds a lazy-loaded topic thumbnail on the left. It requests a 320×240 optimized thumbnail, falls back to the original topic image while optimized thumbnails are generated, and displays a category-colored placeholder for topics without an image.

Gallery presents topics in a responsive, uniform-height grid with 640×480 image backgrounds. Cards retain the title, category, up to two tags (one on mobile), status, statistics, and activity while omitting author details and excerpts. Metadata shares a row beneath the title. A theme-aware overlay keeps card content readable, and topics without images reuse the category-colored placeholder.

Masonry reuses the Gallery image cards in a responsive dense mosaic. Card spans are calculated from each loaded image's intrinsic dimensions and the rendered grid measurements. Landscape images expand across available columns to meet the minimum card height; portrait images extend vertically. Images that still cannot meet the minimum height use containment over a blurred backdrop rather than cropping. Pinned topics without images become short, full-width banners. Narrow viewports keep every card to one column, with a gutter separating cards from the screen edges and navigation border.

The image modifier owns masonry measurement and cleanup. It recalculates on image load, layout changes, and grid resizing, and removes its observer and span overrides when the image or layout changes. Gallery and Masonry share their base grid styles; the containing table uses fixed layout so its intrinsic sizing cannot widen that grid. Layouts that flatten Horizon's footer also disable its mobile scroll-fade pseudo-element, which otherwise overlays cards and timestamps.

These modes assume Horizon's default `topic_card_high_context` setting remains enabled.

## Development

Install this nested theme component's dependencies independently from the main Discourse workspace:

```sh
pnpm install --ignore-workspace --frozen-lockfile
pnpm lint
```

From the Discourse root, run the component's responsive system tests:

```sh
bin/rspec theme-components/horizon-topic-layouts/spec/system/responsive_topic_layouts_spec.rb
```

These cover Gallery, Masonry, and Minimal at 360px, 425px, and desktop widths, including desktop-to-mobile resizing, loaded images, a pinned placeholder, long metadata, and reply timestamps. JavaScript unit and component tests live in `test/`; the component tests cover switching layouts with an already-loaded image and recreating an image before resizing.
