import { isTopicLayout } from "./topic-layouts";

const STORAGE_PREFIX = "horizon-topic-layouts:v1";
const FILTERS = ["latest", "new", "unread", "top"];

export function layoutContextKey(categoryId, routeName) {
  if (categoryId) {
    return `category:${categoryId}`;
  }

  const routeParts = routeName?.split(".") ?? [];
  const filter = FILTERS.find((name) => routeParts.includes(name));

  return filter ? `filter:${filter}` : null;
}

export function preferenceStorageKey(userId, contextKey) {
  return `${STORAGE_PREFIX}:${userId ?? "anonymous"}:${contextKey}`;
}

export function readLayoutPreference(storage, userId, contextKey) {
  if (!storage || !contextKey) {
    return null;
  }

  try {
    const layoutId = storage.getItem(preferenceStorageKey(userId, contextKey));
    return isTopicLayout(layoutId) ? layoutId : null;
  } catch {
    return null;
  }
}

export function removeLayoutPreference(storage, userId, contextKey) {
  if (!storage || !contextKey) {
    return;
  }

  try {
    storage.removeItem(preferenceStorageKey(userId, contextKey));
  } catch {
    // Browsing contexts can deny storage access.
  }
}

export function writeLayoutPreference(storage, userId, contextKey, layoutId) {
  if (!storage || !contextKey || !isTopicLayout(layoutId)) {
    return false;
  }

  try {
    storage.setItem(preferenceStorageKey(userId, contextKey), layoutId);
    return true;
  } catch {
    return false;
  }
}
