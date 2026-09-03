import { apiInitializer } from "discourse/lib/api";
import TopicLayoutSelector from "../components/topic-layout-selector";

export default apiInitializer((api) => {
  const layoutPreferences = api.container.lookup(
    "service:horizon-topic-layout-preferences"
  );

  api.renderInOutlet("before-create-topic-button", TopicLayoutSelector);
  api.onPageChange(() => layoutPreferences.activateCurrentRoute());
});
