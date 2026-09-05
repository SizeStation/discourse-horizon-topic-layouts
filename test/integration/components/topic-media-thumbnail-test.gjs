import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import {
  find,
  render,
  rerender,
  triggerEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import TopicMediaThumbnail from "../../../discourse/components/topic-media-thumbnail";

class LayoutPreferences extends Service {
  @tracked activeLayoutId = "gallery";
}

module("Integration | Component | TopicMediaThumbnail", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.unregister("service:horizon-topic-layout-preferences");
    this.owner.register(
      "service:horizon-topic-layout-preferences",
      LayoutPreferences
    );
    this.preferences = this.owner.lookup(
      "service:horizon-topic-layout-preferences"
    );
    this.outletArgs = { topic: { image_url: "/topic-image.png" } };
  });

  async function loadImage() {
    const image = find(".horizon-topic-media__image");
    Object.defineProperties(image, {
      naturalWidth: { value: 400 },
      naturalHeight: { value: 100 },
    });
    await triggerEvent(image, "load");
    return image;
  }

  async function waitForClassification() {
    await waitUntil(() =>
      find(".topic-list-item").style.getPropertyValue("--topic-media-row-span")
    );
  }

  test("classifies an already loaded image when switching to masonry", async function (assert) {
    await render(
      <template>
        <div
          class="topic-list-body"
          style="display: grid; width: 200px; grid-template-columns: 200px; grid-auto-rows: 2px; gap: 2px;"
        >
          <div class="topic-list-item" style="margin-block-end: 0;">
            <div class="hc-topic-card" style="min-block-size: 100px;">
              <TopicMediaThumbnail @outletArgs={{this.outletArgs}} />
            </div>
          </div>
        </div>
      </template>
    );
    const image = await loadImage();

    this.preferences.activeLayoutId = "masonry";
    await rerender();
    await waitForClassification();

    assert.strictEqual(
      find(".horizon-topic-media__image"),
      image,
      "the same loaded image is reused"
    );
    assert
      .dom(".topic-list-item")
      .hasClass(
        "has-constrained-media",
        "the panorama is constrained to the available column"
      );
    assert.strictEqual(
      find(".topic-list-item").style.getPropertyValue("--topic-media-row-span"),
      "26",
      "masonry uses the rendered grid measurements without another load event"
    );

    this.preferences.activeLayoutId = "gallery";
    await rerender();

    assert
      .dom(".topic-list-item")
      .doesNotHaveClass(
        "has-constrained-media",
        "leaving masonry clears its classification"
      );
    assert.strictEqual(
      find(".topic-list-item").style.getPropertyValue("--topic-media-row-span"),
      "",
      "leaving masonry removes its row span"
    );
    assert.strictEqual(
      find(".topic-list-item").style.getPropertyValue(
        "--topic-media-column-span"
      ),
      "",
      "leaving masonry removes its column span"
    );
  });

  test("classifies a replacement image after media is removed", async function (assert) {
    this.preferences.activeLayoutId = "masonry";
    await render(
      <template>
        <div
          class="topic-list-body"
          style="display: grid; width: 200px; grid-template-columns: 200px; grid-auto-rows: 2px; gap: 2px;"
        >
          <div class="topic-list-item" style="margin-block-end: 0;">
            <div class="hc-topic-card" style="min-block-size: 100px;">
              <TopicMediaThumbnail @outletArgs={{this.outletArgs}} />
            </div>
          </div>
        </div>
      </template>
    );
    const firstImage = await loadImage();
    await waitForClassification();

    this.preferences.activeLayoutId = "comfortable";
    await rerender();
    assert
      .dom(".horizon-topic-media")
      .doesNotExist("native layouts remove media");
    assert
      .dom(".topic-list-item")
      .doesNotHaveClass(
        "has-constrained-media",
        "removing the image clears its classification"
      );

    this.preferences.activeLayoutId = "masonry";
    await rerender();
    const replacementImage = await loadImage();
    await waitForClassification();

    assert.notStrictEqual(
      replacementImage,
      firstImage,
      "a new image is rendered"
    );
    assert
      .dom(".topic-list-item")
      .hasClass("has-constrained-media", "the replacement image is classified");

    const grid = find(".topic-list-body");
    // The QUnit fixture scales rendered geometry, which masonry measures.
    const scale = grid.getBoundingClientRect().width / grid.offsetWidth;
    const width = `${800 / scale}px`;
    grid.style.width = width;
    grid.style.gridTemplateColumns = width;
    await waitUntil(
      () =>
        find(".topic-list-item").style.getPropertyValue(
          "--topic-media-row-span"
        ) === "51"
    );

    assert
      .dom(".topic-list-item")
      .doesNotHaveClass(
        "has-constrained-media",
        "resizing measures the replacement image rather than the removed image"
      );
  });
});
