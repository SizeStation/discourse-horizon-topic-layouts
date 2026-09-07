import { module, test } from "qunit";
import {
  availableTopicLayouts,
  categoryLayoutConfiguration,
  defaultTopicLayout,
  isTopicLayoutAvailable,
  resolveTopicLayout,
} from "../../../discourse/lib/topic-layout-config";

const configurations = [
  {
    categories: [42],
    default_layout: "gallery",
    hide_comfortable: true,
    hide_compact: true,
    hide_minimal: true,
    hide_gallery: true,
  },
];

module("Unit | Lib | topic-layout-config", function () {
  test("finds a configuration using string or numeric category IDs", function (assert) {
    assert.strictEqual(
      categoryLayoutConfiguration("42", configurations),
      configurations[0],
      "the category configuration is found"
    );
  });

  test("applies a shared rule to every selected category", function (assert) {
    const sharedRules = [{ ...configurations[0], categories: [42, "43"] }];

    for (const categoryId of [42, 43]) {
      assert.strictEqual(
        defaultTopicLayout(categoryId, sharedRules, "comfortable"),
        "gallery",
        `category ${categoryId} uses the shared default`
      );
      assert.deepEqual(
        availableTopicLayouts(categoryId, sharedRules, "comfortable").map(
          ({ id }) => id
        ),
        ["media-list", "gallery", "masonry"],
        `category ${categoryId} uses the shared visibility rules`
      );
    }

    assert.strictEqual(
      categoryLayoutConfiguration(7, sharedRules),
      null,
      "unselected categories are unaffected"
    );
  });

  test("uses the first matching rule when category selections overlap", function (assert) {
    const overlappingRules = [
      { ...configurations[0], categories: [42, 43] },
      { categories: [43, 44], default_layout: "compact" },
    ];

    assert.strictEqual(
      categoryLayoutConfiguration(43, overlappingRules),
      overlappingRules[0],
      "the overlapping category uses the first rule"
    );
    assert.strictEqual(
      categoryLayoutConfiguration(44, overlappingRules),
      overlappingRules[1],
      "the other category still uses the second rule"
    );
  });

  test("uses the category default when configured", function (assert) {
    assert.strictEqual(
      defaultTopicLayout(42, configurations, "comfortable"),
      "gallery",
      "the category default wins"
    );
    assert.strictEqual(
      defaultTopicLayout(7, configurations, "compact"),
      "compact",
      "an unconfigured category uses the global default"
    );
  });

  test("treats a rule without hide switches as unrestricted", function (assert) {
    const unrestricted = [
      {
        categories: [42],
        default_layout: "gallery",
      },
    ];

    assert.strictEqual(
      availableTopicLayouts(42, unrestricted, "comfortable").length,
      6,
      "all layouts are available"
    );
  });

  test("always includes the category default when its hide switch is on", function (assert) {
    assert.deepEqual(
      availableTopicLayouts(42, configurations, "comfortable").map(
        ({ id }) => id
      ),
      ["media-list", "gallery", "masonry"],
      "the default is included in canonical layout order"
    );
  });

  test("resolves visible preferences before category and global defaults", function (assert) {
    assert.strictEqual(
      resolveTopicLayout("masonry", 42, configurations, "comfortable"),
      "masonry",
      "a visible user preference wins"
    );
    assert.strictEqual(
      resolveTopicLayout("compact", 42, configurations, "comfortable"),
      "gallery",
      "a hidden preference falls back to the category default"
    );
    assert.strictEqual(
      resolveTopicLayout(null, 7, configurations, "comfortable"),
      "comfortable",
      "an unconfigured category falls back to the global default"
    );
  });

  test("identifies layouts hidden by a category rule", function (assert) {
    assert.true(
      isTopicLayoutAvailable("media-list", 42, configurations, "comfortable"),
      "a visible layout is available"
    );
    assert.false(
      isTopicLayoutAvailable("compact", 42, configurations, "comfortable"),
      "a hidden layout is unavailable"
    );
  });
});
