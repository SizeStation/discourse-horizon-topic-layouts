import Component from "@glimmer/component";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import dIcon from "discourse/ui-kit/helpers/d-icon";

const CATEGORY_COLOR_PATTERN = /^[0-9a-f]{6}$/i;
const TOPIC_MEDIA_SIZES = Object.freeze({
  gallery: [640, 480],
  masonry: [640, 480],
  "media-list": [320, 240],
});

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
    const topic = this.args.outletArgs.topic;
    const [maxWidth, maxHeight] =
      TOPIC_MEDIA_SIZES[this.layoutPreferences.activeLayoutId] ?? [];
    const thumbnail = topic.thumbnails?.find(
      ({ max_height, max_width }) =>
        max_height === maxHeight && max_width === maxWidth
    );

    return thumbnail?.url ?? topic.image_url;
  }

  get shouldRender() {
    return Boolean(TOPIC_MEDIA_SIZES[this.layoutPreferences.activeLayoutId]);
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
