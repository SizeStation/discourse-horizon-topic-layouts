export const TOPIC_MEDIA_SIZES = Object.freeze({
  gallery: [640, 480],
  masonry: [640, 480],
  "media-list": [320, 240],
});

const DEFAULT_MASONRY_METRICS = Object.freeze({
  columnGap: 1,
  columnWidth: 17,
  itemGap: 1,
  maxColumnSpan: 3,
  minimumHeight: 18,
  rowGap: 0.125,
  rowHeight: 0.125,
});

function topicMediaDimensions(topic) {
  return topic.thumbnails?.find(
    ({ height, width }) =>
      Number.isFinite(width) &&
      width > 0 &&
      Number.isFinite(height) &&
      height > 0
  );
}

export function topicMediaAspectRatio(topic) {
  const thumbnail = topicMediaDimensions(topic);

  return thumbnail ? `${thumbnail.width} / ${thumbnail.height}` : null;
}

export function topicMediaMasonrySpans(
  topic,
  metrics = DEFAULT_MASONRY_METRICS
) {
  const thumbnail = topicMediaDimensions(topic);
  const aspectRatio = thumbnail ? thumbnail.width / thumbnail.height : 1;
  let columnSpan = 1;
  let targetWidth = metrics.columnWidth;

  while (
    targetWidth / aspectRatio < metrics.minimumHeight &&
    columnSpan < metrics.maxColumnSpan
  ) {
    columnSpan += 1;
    targetWidth =
      metrics.columnWidth * columnSpan + metrics.columnGap * (columnSpan - 1);
  }

  const imageHeight = targetWidth / aspectRatio;
  const isConstrained = imageHeight < metrics.minimumHeight;
  const targetHeight = Math.max(metrics.minimumHeight, imageHeight);
  const rowSpan = Math.ceil(
    (targetHeight + metrics.itemGap + metrics.rowGap) /
      (metrics.rowHeight + metrics.rowGap)
  );

  return { columnSpan, isConstrained, rowSpan };
}

export function topicMediaImageUrl(topic, layoutId) {
  const [maxWidth, maxHeight] = TOPIC_MEDIA_SIZES[layoutId] ?? [];
  const thumbnail = topic.thumbnails?.find(
    ({ max_height, max_width }) =>
      max_height === maxHeight && max_width === maxWidth
  );

  return thumbnail?.url ?? topic.image_url;
}

export function usesTopicMedia(layoutId) {
  return Boolean(TOPIC_MEDIA_SIZES[layoutId]);
}
