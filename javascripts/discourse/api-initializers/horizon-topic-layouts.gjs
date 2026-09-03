import { apiInitializer } from "discourse/lib/api";
import TopicLayoutSelector from "../components/topic-layout-selector";
import TopicMediaThumbnail from "../components/topic-media-thumbnail";

export default apiInitializer((api) => {
  const layoutPreferences = api.container.lookup(
    "service:horizon-topic-layout-preferences"
  );

  api.renderInOutlet("before-create-topic-button", TopicLayoutSelector);
  api.renderInOutlet("topic-list-after-title", TopicMediaThumbnail);
  api.onPageChange(() => layoutPreferences.activateCurrentRoute());
});
