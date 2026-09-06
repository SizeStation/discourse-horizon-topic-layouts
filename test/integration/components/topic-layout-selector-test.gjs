import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { render, rerender } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import TopicLayoutSelector from "../../../discourse/components/topic-layout-selector";
import { findTopicLayout } from "../../../discourse/lib/topic-layouts";

class LayoutPreferences extends Service {
  @tracked availableLayouts = [findTopicLayout("gallery")];
  @tracked isSupportedContext = true;

  activeLayout = findTopicLayout("gallery");
  isCategoryContext = true;

  activateContext(categoryId) {
    this.categoryId = categoryId;
  }
}

module("Integration | Component | TopicLayoutSelector", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.unregister("service:horizon-topic-layout-preferences");
    this.owner.register(
      "service:horizon-topic-layout-preferences",
      LayoutPreferences
    );
    this.preferences = this.owner.lookup(
      "service:horizon-topic-layout-preferences"
    );
    this.outletArgs = { category: { id: 42 } };
  });

  test("only shows the selector when there is a choice of layouts", async function (assert) {
    await render(
      <template>
        <TopicLayoutSelector @outletArgs={{this.outletArgs}} />
      </template>
    );

    assert
      .dom(".horizon-topic-layout-selector")
      .doesNotExist("one layout needs no selector or wrapper");
    assert.strictEqual(
      this.preferences.categoryId,
      this.outletArgs.category.id,
      "the category context is still activated when the selector is hidden"
    );

    this.preferences.availableLayouts = [
      findTopicLayout("gallery"),
      findTopicLayout("minimal"),
    ];
    await rerender();

    assert
      .dom(".horizon-topic-layout-selector__trigger")
      .exists("a choice of layouts shows the selector");

    this.preferences.availableLayouts = [findTopicLayout("gallery")];
    await rerender();

    assert
      .dom(".horizon-topic-layout-selector")
      .doesNotExist("returning to a single layout removes the selector");
  });
});
