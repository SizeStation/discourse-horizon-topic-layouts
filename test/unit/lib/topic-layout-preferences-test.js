import { module, test } from "qunit";
import {
  layoutContextKey,
  preferenceStorageKey,
  readLayoutPreference,
  removeLayoutPreference,
  writeLayoutPreference,
} from "../../../discourse/lib/topic-layout-preferences";

function memoryStorage() {
  const values = new Map();

  return {
    getItem(key) {
      return values.get(key) ?? null;
    },
    removeItem(key) {
      values.delete(key);
    },
    setItem(key, value) {
      values.set(key, value);
    },
  };
}

module("Unit | Lib | topic-layout-preferences", function () {
  test("builds contexts for categories and supported filters", function (assert) {
    assert.strictEqual(
      layoutContextKey(42, "discovery.category"),
      "category:42",
      "a category has its own context"
    );
    assert.strictEqual(
      layoutContextKey(null, "discovery.latest"),
      "filter:latest",
      "latest has its own context"
    );
    assert.strictEqual(
      layoutContextKey(null, "discovery.top"),
      "filter:top",
      "top has its own context"
    );
    assert.strictEqual(
      layoutContextKey(null, "discovery.categories"),
      null,
      "unsupported routes have no context"
    );
  });

  test("isolates preferences by user and context", function (assert) {
    assert.notStrictEqual(
      preferenceStorageKey(1, "category:42"),
      preferenceStorageKey(2, "category:42"),
      "users have separate preferences"
    );
    assert.notStrictEqual(
      preferenceStorageKey(1, "category:42"),
      preferenceStorageKey(1, "filter:latest"),
      "contexts have separate preferences"
    );
  });

  test("writes, reads, and removes a valid preference", function (assert) {
    const storage = memoryStorage();

    assert.true(
      writeLayoutPreference(storage, 1, "category:42", "gallery"),
      "the preference is written"
    );
    assert.strictEqual(
      readLayoutPreference(storage, 1, "category:42"),
      "gallery",
      "the preference is read"
    );

    removeLayoutPreference(storage, 1, "category:42");

    assert.strictEqual(
      readLayoutPreference(storage, 1, "category:42"),
      null,
      "the preference is removed"
    );
  });

  test("rejects unknown layouts", function (assert) {
    const storage = memoryStorage();

    assert.false(
      writeLayoutPreference(storage, 1, "filter:latest", "unknown"),
      "an unknown layout is not written"
    );
  });
});
