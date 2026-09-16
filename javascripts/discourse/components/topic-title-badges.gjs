import Component from "@glimmer/component";
import { service } from "@ember/service";
import TopicPostBadges from "discourse/components/topic-post-badges";

export default class TopicTitleBadges extends Component {
  @service("horizon-topic-layout-preferences") layoutPreferences;

  get shouldRender() {
    return (
      ["gallery", "masonry"].includes(this.layoutPreferences.activeLayoutId) &&
      (this.args.outletArgs.topic.unseen ||
        this.args.outletArgs.topic.unread_posts)
    );
  }

  <template>
    {{#if this.shouldRender}}
      <span class="horizon-topic-title-badges" ...attributes>
        <TopicPostBadges
          @unreadPosts={{@outletArgs.topic.unread_posts}}
          @unseen={{@outletArgs.topic.unseen}}
          @url={{@outletArgs.topic.lastUnreadUrl}}
        />{{~! Keep the leading badge attached to the first title character. ~}}&#8288;</span>
    {{~/if~}}
  </template>
}
