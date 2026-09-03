import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { settings } from "virtual:theme";
import {
  availableTopicLayouts,
  defaultTopicLayout,
  isTopicLayoutAvailable,
  resolveTopicLayout,
} from "../lib/topic-layout-config";
import {
  layoutContextKey,
  readLayoutPreference,
  removeLayoutPreference,
  writeLayoutPreference,
} from "../lib/topic-layout-preferences";
import {
  DEFAULT_TOPIC_LAYOUT,
  findTopicLayout,
  TOPIC_LAYOUTS,
} from "../lib/topic-layouts";

const layoutClass = (layoutId) => `horizon-topic-layouts--${layoutId}`;

export default class HorizonTopicLayoutPreferences extends Service {
  @service currentUser;
  @service router;

  @tracked activeLayoutId = DEFAULT_TOPIC_LAYOUT;
  @tracked contextKey = null;
  @tracked _categoryId = null;

  get activeLayout() {
    return findTopicLayout(this.activeLayoutId);
  }

  get availableLayouts() {
    return availableTopicLayouts(
      this._categoryId,
      settings.category_layout_rules,
      settings.global_default_layout
    );
  }

  get isCategoryContext() {
    return Boolean(this._categoryId);
  }

  get isSupportedContext() {
    return Boolean(this.contextKey);
  }

  activateContext(categoryId, routeName = this.router.currentRouteName) {
    const contextKey = layoutContextKey(categoryId, routeName);
    const storedLayout = readLayoutPreference(
      this.#storage,
      this.#userId,
      contextKey
    );

    this._categoryId = categoryId ?? null;
    this.contextKey = contextKey;
    this.activeLayoutId = resolveTopicLayout(
      storedLayout,
      this._categoryId,
      settings.category_layout_rules,
      settings.global_default_layout
    );
    this.#applyLayoutClass();
  }

  activateCurrentRoute() {
    this.activateContext(this.#categoryIdFromCurrentRoute());
  }

  resetLayout() {
    removeLayoutPreference(this.#storage, this.#userId, this.contextKey);
    this.activeLayoutId = this.#defaultLayoutId;
    this.#applyLayoutClass();
  }

  selectLayout(layoutId) {
    if (
      !this.contextKey ||
      !isTopicLayoutAvailable(
        layoutId,
        this._categoryId,
        settings.category_layout_rules,
        settings.global_default_layout
      )
    ) {
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
    return defaultTopicLayout(
      this._categoryId,
      settings.category_layout_rules,
      settings.global_default_layout
    );
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

  #categoryIdFromCurrentRoute() {
    for (let route = this.router.currentRoute; route; route = route.parent) {
      const categoryPath = route.params?.category_slug_path_with_id;

      if (categoryPath) {
        const categoryId = Number(categoryPath.split("/").at(-1));
        return categoryId > 0 ? categoryId : null;
      }
    }

    return null;
  }
}
