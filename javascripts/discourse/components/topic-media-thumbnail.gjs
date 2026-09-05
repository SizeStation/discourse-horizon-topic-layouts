import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import { modifier } from "ember-modifier";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import {
  topicMediaImageUrl,
  topicMediaMasonrySpans,
  usesTopicMedia,
} from "../lib/topic-media";

const CATEGORY_COLOR_PATTERN = /^[0-9a-f]{6}$/i;

export default class TopicMediaThumbnail extends Component {
  @service("horizon-topic-layout-preferences") layoutPreferences;

  classifyImage = modifier((image, [isMasonry]) => {
    const topicCard = image.closest(".topic-list-item");
    const topicGrid = topicCard?.closest(".topic-list-body");

    if (!isMasonry || !topicGrid) {
      return;
    }

    let classificationFrame;
    let gridInlineSize;
    const scheduleClassification = () => {
      globalThis.cancelAnimationFrame(classificationFrame);
      classificationFrame = globalThis.requestAnimationFrame(() => {
        if (image.isConnected && image.naturalWidth && image.naturalHeight) {
          this.#classifyLoadedImage(image, topicCard);
        }
      });
    };
    const resizeObserver = new ResizeObserver(([entry]) => {
      const inlineSize = entry.contentRect.width;

      if (inlineSize !== gridInlineSize) {
        gridInlineSize = inlineSize;
        scheduleClassification();
      }
    });

    image.addEventListener("load", scheduleClassification);
    resizeObserver.observe(topicGrid);
    scheduleClassification();

    return () => {
      globalThis.cancelAnimationFrame(classificationFrame);
      resizeObserver.disconnect();
      image.removeEventListener("load", scheduleClassification);
      topicCard.style.removeProperty("--topic-media-column-span");
      topicCard.style.removeProperty("--topic-media-row-span");
      topicCard.classList.remove("has-constrained-media");
    };
  });

  get categoryColorStyle() {
    const color = this.args.outletArgs.topic.category?.color;

    if (!CATEGORY_COLOR_PATTERN.test(color)) {
      return;
    }

    return trustHTML(`--topic-media-category-color: #${color}`);
  }

  get imageUrl() {
    return topicMediaImageUrl(
      this.args.outletArgs.topic,
      this.layoutPreferences.activeLayoutId
    );
  }

  get isMasonry() {
    return this.layoutPreferences.activeLayoutId === "masonry";
  }

  get shouldRender() {
    return usesTopicMedia(this.layoutPreferences.activeLayoutId);
  }

  #classifyLoadedImage(image, topicCard) {
    const card = image.closest(".hc-topic-card");
    const masonryGrid = topicCard.closest(".topic-list-body");

    if (!card || !masonryGrid) {
      return;
    }

    topicCard.style.setProperty("--topic-media-column-span", 1);

    const cardStyles = globalThis.getComputedStyle(card);
    const gridStyles = globalThis.getComputedStyle(masonryGrid);
    const itemStyles = globalThis.getComputedStyle(topicCard);
    const columnGap = Number.parseFloat(gridStyles.columnGap);
    const columnWidth = topicCard.getBoundingClientRect().width;
    const metrics = {
      columnGap,
      columnWidth,
      itemGap: Number.parseFloat(itemStyles.marginBlockEnd),
      maxColumnSpan: Math.max(
        1,
        Math.round(
          (masonryGrid.getBoundingClientRect().width + columnGap) /
            (columnWidth + columnGap)
        )
      ),
      minimumHeight: Number.parseFloat(cardStyles.minBlockSize),
      rowGap: Number.parseFloat(gridStyles.rowGap),
      rowHeight: Number.parseFloat(gridStyles.gridAutoRows),
    };

    const { columnSpan, isConstrained, rowSpan } = topicMediaMasonrySpans(
      {
        thumbnails: [
          { height: image.naturalHeight, width: image.naturalWidth },
        ],
      },
      metrics
    );

    topicCard.style.setProperty("--topic-media-column-span", columnSpan);
    topicCard.style.setProperty("--topic-media-row-span", rowSpan);
    topicCard.classList.toggle("has-constrained-media", isConstrained);
  }

  <template>
    {{#if this.shouldRender}}
      <div class="horizon-topic-media" aria-hidden="true">
        {{#if this.imageUrl}}
          {{#if this.isMasonry}}
            <img
              class="horizon-topic-media__backdrop"
              src={{this.imageUrl}}
              alt=""
              loading="lazy"
              decoding="async"
            />
          {{/if}}
          <img
            class="horizon-topic-media__image"
            src={{this.imageUrl}}
            alt=""
            loading="lazy"
            decoding="async"
            {{this.classifyImage this.isMasonry this.imageUrl}}
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
