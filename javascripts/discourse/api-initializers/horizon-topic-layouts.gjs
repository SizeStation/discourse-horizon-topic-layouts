import { apiInitializer } from "discourse/lib/api";
import TopicLayoutSelector from "../components/topic-layout-selector";

export default apiInitializer((api) => {
  api.renderInOutlet("before-create-topic-button", TopicLayoutSelector);
});
