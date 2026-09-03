import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import {
  topicMediaImageUrl,
  topicMediaMasonrySpans,
  usesTopicMedia,
} from "../lib/topic-media";

const CATEGORY_COLOR_PATTERN = /^[0-9a-f]{6}$/i;

export default class TopicMediaThumbnail extends Component {
  @service("horizon-topic-layout-preferences") layoutPreferences;

  get categoryColorStyle() {
    const color = this.args.outletArgs.topic.category?.color;

    if (!CATEGORY_COLOR_PATTERN.test(color)) {
      return;
    }

    return htmlSafe(`--topic-media-category-color: #${color}`);
  }

  get imageUrl() {
    return topicMediaImageUrl(
      this.args.outletArgs.topic,
      this.layoutPreferences.activeLayoutId
    );
  }

  get shouldRender() {
    return usesTopicMedia(this.layoutPreferences.activeLayoutId);
  }

  @action
  classifyImage(event) {
    const image = event.currentTarget;
    const topicCard = image.closest(".topic-list-item");

    if (!topicCard) {
      return;
    }

    requestAnimationFrame(() => this.#classifyLoadedImage(image, topicCard));
  }

  #classifyLoadedImage(image, topicCard) {
    if (!topicCard.isConnected) {
      return;
    }

    topicCard.style.setProperty("--topic-media-column-span", 1);

    const masonryGrid = topicCard.closest(".topic-list-body");
    let metrics;

    if (masonryGrid && this.layoutPreferences.activeLayoutId === "masonry") {
      const cardStyles = globalThis.getComputedStyle(
        image.closest(".hc-topic-card")
      );
      const gridStyles = globalThis.getComputedStyle(masonryGrid);
      const itemStyles = globalThis.getComputedStyle(topicCard);
      const columnGap = Number.parseFloat(gridStyles.columnGap);
      const columnWidth = topicCard.getBoundingClientRect().width;
      metrics = {
        columnGap,
        columnWidth,
        itemGap: Number.parseFloat(itemStyles.marginBlockEnd),
        maxColumnSpan: Math.max(
          1,
          Math.floor(
            (masonryGrid.getBoundingClientRect().width + columnGap) /
              (columnWidth + columnGap)
          )
        ),
        minimumHeight: Number.parseFloat(cardStyles.minBlockSize),
        rowGap: Number.parseFloat(gridStyles.rowGap),
        rowHeight: Number.parseFloat(gridStyles.gridAutoRows),
      };
    }

    const { columnSpan, rowSpan } = topicMediaMasonrySpans(
      {
        thumbnails: [
          { height: image.naturalHeight, width: image.naturalWidth },
        ],
      },
      metrics
    );

    topicCard.style.setProperty("--topic-media-column-span", columnSpan);
    topicCard.style.setProperty("--topic-media-row-span", rowSpan);
  }

  <template>
    {{#if this.shouldRender}}
      <div class="horizon-topic-media" aria-hidden="true">
        {{#if this.imageUrl}}
          <img
            class="horizon-topic-media__image"
            src={{this.imageUrl}}
            alt=""
            loading="lazy"
            decoding="async"
            {{on "load" this.classifyImage}}
          />
        {{else}}
          <div
            class="horizon-topic-media__placeholder"
            style={{this.categoryColorStyle}}
          >
            {{dIcon "image"}}
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
