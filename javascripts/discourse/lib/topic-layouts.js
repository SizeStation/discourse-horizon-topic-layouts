import { themePrefix } from "virtual:theme";

export const DEFAULT_TOPIC_LAYOUT = "comfortable";

export const TOPIC_LAYOUTS = Object.freeze([
  {
    id: "comfortable",
    icon: "rectangle-list",
    label: themePrefix("selector.layouts.comfortable"),
  },
  {
    id: "compact",
    icon: "bars-staggered",
    label: themePrefix("selector.layouts.compact"),
  },
  {
    id: "minimal",
    icon: "align-justify",
    label: themePrefix("selector.layouts.minimal"),
  },
  {
    id: "media-list",
    icon: "table-list",
    label: themePrefix("selector.layouts.media_list"),
  },
  {
    id: "gallery",
    icon: "grip",
    label: themePrefix("selector.layouts.gallery"),
  },
  {
    id: "masonry",
    icon: "cubes-stacked",
    label: themePrefix("selector.layouts.masonry"),
  },
]);

export function findTopicLayout(layoutId) {
  return TOPIC_LAYOUTS.find(({ id }) => id === layoutId);
}

export function isTopicLayout(layoutId) {
  return Boolean(findTopicLayout(layoutId));
}
