import {
  topicMediaAspectRatio,
  topicMediaImageUrl,
  topicMediaMasonrySpans,
  usesTopicMedia,
} from "horizon-topic-layouts/discourse/lib/topic-media";
import { module, test } from "qunit";

module("Unit | Lib | topic-media", function () {
  test("selects the thumbnail requested for each layout", function (assert) {
    const topic = {
      image_url: "/original.jpg",
      thumbnails: [
        { max_height: 240, max_width: 320, url: "/media-list.jpg" },
        { max_height: 480, max_width: 640, url: "/gallery.jpg" },
      ],
    };

    assert.strictEqual(
      topicMediaImageUrl(topic, "media-list"),
      "/media-list.jpg",
      "media list uses its smaller thumbnail"
    );
    assert.strictEqual(
      topicMediaImageUrl(topic, "masonry"),
      "/gallery.jpg",
      "masonry uses the larger image-card thumbnail"
    );
  });

  test("falls back to the original topic image", function (assert) {
    assert.strictEqual(
      topicMediaImageUrl({ image_url: "/original.jpg" }, "gallery"),
      "/original.jpg",
      "the original is used while a requested thumbnail is unavailable"
    );
  });

  test("returns a validated thumbnail aspect ratio", function (assert) {
    assert.strictEqual(
      topicMediaAspectRatio({ thumbnails: [{ height: 480, width: 640 }] }),
      "640 / 480",
      "positive numeric dimensions produce a ratio"
    );
    assert.strictEqual(
      topicMediaAspectRatio({ thumbnails: [{ height: 0, width: 640 }] }),
      null,
      "invalid dimensions do not produce a ratio"
    );
  });

  test("assigns masonry spans from image orientation", function (assert) {
    assert.deepEqual(
      topicMediaMasonrySpans({
        thumbnails: [{ height: 400, width: 800 }],
      }),
      { columnSpan: 3, isConstrained: false, rowSpan: 111 },
      "a panoramic image spans enough columns to retain the minimum height"
    );
    assert.deepEqual(
      topicMediaMasonrySpans({
        thumbnails: [{ height: 400, width: 600 }],
      }),
      { columnSpan: 2, isConstrained: false, rowSpan: 98 },
      "an ordinary landscape image expands to retain the minimum height"
    );
    assert.deepEqual(
      topicMediaMasonrySpans({
        thumbnails: [{ height: 400, width: 1600 }],
      }),
      { columnSpan: 3, isConstrained: true, rowSpan: 77 },
      "an extra-wide image spans enough columns to retain the minimum height"
    );
    assert.deepEqual(
      topicMediaMasonrySpans({
        thumbnails: [{ height: 800, width: 400 }],
      }),
      { columnSpan: 1, isConstrained: false, rowSpan: 141 },
      "a tall image receives enough rows for its aspect ratio"
    );
    assert.deepEqual(
      topicMediaMasonrySpans({}),
      { columnSpan: 2, isConstrained: false, rowSpan: 145 },
      "a topic without image dimensions is treated as a square tile"
    );
    assert.deepEqual(
      topicMediaMasonrySpans(
        { thumbnails: [{ height: 400, width: 1600 }] },
        {
          columnGap: 1,
          columnWidth: 17,
          itemGap: 1,
          maxColumnSpan: 1,
          minimumHeight: 14,
          rowGap: 0.125,
          rowHeight: 0.125,
        }
      ),
      { columnSpan: 1, isConstrained: true, rowSpan: 61 },
      "an image cannot exceed the columns available on a narrow viewport"
    );
  });

  test("identifies layouts that render topic media", function (assert) {
    assert.true(usesTopicMedia("media-list"), "media list renders topic media");
    assert.true(usesTopicMedia("gallery"), "gallery renders topic media");
    assert.true(usesTopicMedia("masonry"), "masonry renders topic media");
    assert.false(usesTopicMedia("comfortable"), "comfortable remains native");
  });
});
