import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const TopicLayoutTrigger = <template>
  <button
    type="button"
    class="btn btn-default horizon-topic-layout-selector__trigger"
    aria-label={{@label}}
    title={{@label}}
    ...attributes
  >
    {{dIcon @layout.icon}}
    {{dIcon "angle-down" class="horizon-topic-layout-selector__trigger-caret"}}
  </button>
</template>;

export default class TopicLayoutSelector extends Component {
  @service("horizon-topic-layout-preferences") layoutPreferences;

  constructor() {
    super(...arguments);
    this.layoutPreferences.activateContext(this.#initialCategoryId);
  }

  get activeLayout() {
    return this.layoutPreferences.activeLayout;
  }

  get layouts() {
    return this.layoutPreferences.availableLayouts;
  }

  get resetLabel() {
    return themePrefix(
      this.layoutPreferences.isCategoryContext
        ? "selector.use_category_default"
        : "selector.use_global_default"
    );
  }

  get shouldRender() {
    return this.layoutPreferences.isSupportedContext && this.layouts.length > 1;
  }

  get triggerLabel() {
    return i18n(this.activeLayout.label);
  }

  get #initialCategoryId() {
    return this.args.outletArgs.category?.id;
  }

  @action
  async resetLayout(dMenu) {
    this.layoutPreferences.resetLayout();
    await dMenu.close();
  }

  @action
  async selectLayout(layoutId, dMenu) {
    this.layoutPreferences.selectLayout(layoutId);
    await dMenu.close();
  }

  <template>
    {{#if this.shouldRender}}
      <div class="horizon-topic-layout-selector">
        <DMenu
          @contentClass="horizon-topic-layout-selector__menu"
          @identifier="horizon-topic-layout-selector"
          @modalForMobile={{true}}
          @triggerComponent={{component
            TopicLayoutTrigger
            label=this.triggerLabel
            layout=this.activeLayout
          }}
        >
          <:content as |dMenu|>
            <DDropdownMenu
              class="horizon-topic-layout-selector__options"
              as |dropdown|
            >
              {{#each this.layouts as |layout|}}
                <dropdown.item>
                  <div class="horizon-topic-layout-selector__option-wrapper">
                    <DButton
                      class={{dConcatClass
                        "btn-flat horizon-topic-layout-selector__option"
                        (if (eq layout.id this.activeLayout.id) "is-active")
                      }}
                      aria-pressed={{eq layout.id this.activeLayout.id}}
                      @action={{fn this.selectLayout layout.id dMenu}}
                      @icon={{layout.icon}}
                      @label={{layout.label}}
                    />
                    {{#if (eq layout.id this.activeLayout.id)}}
                      {{dIcon
                        "check"
                        class="horizon-topic-layout-selector__selected-icon"
                      }}
                    {{/if}}
                  </div>
                </dropdown.item>
              {{/each}}

              <dropdown.item>
                <DButton
                  class="btn-flat horizon-topic-layout-selector__reset"
                  @action={{fn this.resetLayout dMenu}}
                  @icon="rotate-left"
                  @label={{this.resetLabel}}
                />
              </dropdown.item>
            </DDropdownMenu>
          </:content>
        </DMenu>
      </div>
    {{/if}}
  </template>
}
