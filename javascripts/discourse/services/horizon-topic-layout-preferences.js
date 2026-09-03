import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { settings } from "virtual:theme";
import {
  layoutContextKey,
  readLayoutPreference,
  removeLayoutPreference,
  writeLayoutPreference,
} from "../lib/topic-layout-preferences";
import {
  DEFAULT_TOPIC_LAYOUT,
  findTopicLayout,
  isTopicLayout,
  TOPIC_LAYOUTS,
} from "../lib/topic-layouts";

const layoutClass = (layoutId) => `horizon-topic-layouts--${layoutId}`;

export default class HorizonTopicLayoutPreferences extends Service {
  @service currentUser;

  @tracked activeLayoutId = DEFAULT_TOPIC_LAYOUT;
  @tracked contextKey = null;

  get activeLayout() {
    return findTopicLayout(this.activeLayoutId);
  }

  get isSupportedContext() {
    return Boolean(this.contextKey);
  }

  activateContext(categoryId, routeName) {
    const contextKey = layoutContextKey(categoryId, routeName);
    const storedLayout = readLayoutPreference(
      this.#storage,
      this.#userId,
      contextKey
    );

    this.contextKey = contextKey;
    this.activeLayoutId = storedLayout ?? this.#defaultLayoutId;
    this.#applyLayoutClass();
  }

  deactivateContext() {
    this.contextKey = null;
    this.activeLayoutId = this.#defaultLayoutId;
    this.#applyLayoutClass();
  }

  resetLayout() {
    removeLayoutPreference(this.#storage, this.#userId, this.contextKey);
    this.activeLayoutId = this.#defaultLayoutId;
    this.#applyLayoutClass();
  }

  selectLayout(layoutId) {
    if (!this.contextKey || !isTopicLayout(layoutId)) {
      return;
    }

    writeLayoutPreference(
      this.#storage,
      this.#userId,
      this.contextKey,
      layoutId
    );
    this.activeLayoutId = layoutId;
    this.#applyLayoutClass();
  }

  get #defaultLayoutId() {
    return isTopicLayout(settings.global_default_layout)
      ? settings.global_default_layout
      : DEFAULT_TOPIC_LAYOUT;
  }

  get #storage() {
    try {
      return globalThis.localStorage;
    } catch {
      return null;
    }
  }

  get #userId() {
    return this.currentUser?.id ?? "anonymous";
  }

  #applyLayoutClass() {
    const root = globalThis.document?.documentElement;

    if (!root) {
      return;
    }

    root.classList.remove(...TOPIC_LAYOUTS.map(({ id }) => layoutClass(id)));

    if (this.contextKey) {
      root.classList.add(layoutClass(this.activeLayoutId));
    }
  }
}
