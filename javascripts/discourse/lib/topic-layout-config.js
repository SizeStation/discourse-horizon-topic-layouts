import {
  DEFAULT_TOPIC_LAYOUT,
  isTopicLayout,
  TOPIC_LAYOUTS,
} from "./topic-layouts";

const HIDE_SETTING_BY_LAYOUT = {
  comfortable: "hide_comfortable",
  compact: "hide_compact",
  minimal: "hide_minimal",
  "media-list": "hide_media_list",
  gallery: "hide_gallery",
  masonry: "hide_masonry",
};

export function categoryLayoutConfiguration(categoryId, configurations) {
  if (!categoryId || !Array.isArray(configurations)) {
    return null;
  }

  return (
    configurations.find(({ categories }) =>
      categories?.some((configuredId) =>
        categoryIdsMatch(configuredId, categoryId)
      )
    ) ?? null
  );
}

export function defaultTopicLayout(categoryId, configurations, globalDefault) {
  const fallback = isTopicLayout(globalDefault)
    ? globalDefault
    : DEFAULT_TOPIC_LAYOUT;
  const configuredDefault = categoryLayoutConfiguration(
    categoryId,
    configurations
  )?.default_layout;

  return isTopicLayout(configuredDefault) ? configuredDefault : fallback;
}

export function availableTopicLayouts(
  categoryId,
  configurations,
  globalDefault
) {
  const configuration = categoryLayoutConfiguration(categoryId, configurations);

  if (!configuration) {
    return TOPIC_LAYOUTS;
  }

  const defaultLayout = defaultTopicLayout(
    categoryId,
    configurations,
    globalDefault
  );

  return TOPIC_LAYOUTS.filter(
    ({ id }) =>
      id === defaultLayout || !configuration[HIDE_SETTING_BY_LAYOUT[id]]
  );
}

export function isTopicLayoutAvailable(
  layoutId,
  categoryId,
  configurations,
  globalDefault
) {
  return availableTopicLayouts(categoryId, configurations, globalDefault).some(
    ({ id }) => id === layoutId
  );
}

export function resolveTopicLayout(
  preferredLayout,
  categoryId,
  configurations,
  globalDefault
) {
  return isTopicLayoutAvailable(
    preferredLayout,
    categoryId,
    configurations,
    globalDefault
  )
    ? preferredLayout
    : defaultTopicLayout(categoryId, configurations, globalDefault);
}

function categoryIdsMatch(firstId, secondId) {
  return String(firstId) === String(secondId);
}
