# frozen_string_literal: true

module PageObjects
  module Components
    class ResponsiveTopicCards < PageObjects::Components::Base
      def has_layout?(layout, count:)
        page.has_css?(
          ".horizon-topic-layouts--#{layout} .topic-list-item.--high-context .hc-topic-card",
          count: count,
        )
      end

      def has_last_reply?(topic)
        page.has_css?(
          ".topic-list-item[data-topic-id='#{topic.id}'] .hc-topic-card__last-reply .hc-topic-card__time",
          text: "3 days ago",
        )
      end

      def has_pinned_topic?(topic)
        page.has_css?(
          ".topic-list-item[data-topic-id='#{topic.id}'] .hc-topic-card__status.--pinned",
        )
      end

      def has_visible_tags?(topic, tags)
        page.has_css?(
          ".topic-list-item[data-topic-id='#{topic.id}'] .hc-topic-card__tags",
        ) do |list|
          list.all(".discourse-tag").map { |tag| tag["data-tag-name"] } == tags.map(&:name)
        end
      end

      def has_hidden_tag?(topic, tag)
        page.has_css?(
          ".topic-list-item[data-topic-id='#{topic.id}'] .discourse-tag[data-tag-name='#{tag.name}']",
          visible: :hidden,
        )
      end

      def has_no_tags?(topic)
        page.has_no_css?(".topic-list-item[data-topic-id='#{topic.id}'] .discourse-tag")
      end

      def has_loaded_images?(count:)
        page.has_css?(".horizon-topic-media__image", count: count) do |image|
          image.evaluate_script("this.complete && this.naturalWidth > 0")
        end
      end

      def has_multicolumn_image?(topic)
        page.has_css?(".topic-list-item[data-topic-id='#{topic.id}']") do |card|
          card.evaluate_script(
            "parseInt(getComputedStyle(this).gridColumnStart.replace('span ', ''), 10)",
          ) > 1
        end
      end

      def dimensions
        page.evaluate_script(<<~JS)
          (() => {
            const grid = document.querySelector(".topic-list.--d-topic-cards .topic-list-body");
            const controls = document.querySelector(".list-controls");
            const table = grid.closest(".topic-list");
            const tablePadding = parseFloat(getComputedStyle(table).paddingTop);
            const gridBounds = grid.getBoundingClientRect();
            const cards = Array.from(grid.querySelectorAll(".hc-topic-card"));

            return {
              viewportWidth: window.innerWidth,
              documentWidth: document.documentElement.scrollWidth,
              gridLeft: gridBounds.left,
              gridRight: gridBounds.right,
              gapAboveGrid: table.getBoundingClientRect().top + tablePadding - controls.getBoundingClientRect().bottom,
              cards: cards.map((card) => {
                const bounds = card.getBoundingClientRect();
                const footer = card.querySelector(".hc-topic-card__footer");
                const visibleBounds = (selector) => {
                  return Array.from(card.querySelectorAll(selector))
                    .map((element) => element.getBoundingClientRect().toJSON())
                    .find((rectangle) => rectangle.width > 0 && rectangle.height > 0) || null;
                };

                return {
                  left: bounds.left,
                  right: bounds.right,
                  top: bounds.top,
                  bottom: bounds.bottom,
                  innerRight: bounds.right - parseFloat(getComputedStyle(card).paddingRight),
                  title: visibleBounds(".hc-topic-card__content"),
                  tags: visibleBounds(".hc-topic-card__tags") ? visibleBounds(".hc-topic-card__category-tags") : null,
                  replies: visibleBounds(".hc-topic-card__replies"),
                  activity: visibleBounds(".hc-topic-card__time, .hc-topic-card__op-timestamp"),
                  metadata: Array.from(card.querySelectorAll(
                    ".hc-topic-card__content, .hc-topic-card__category-tags, .hc-topic-card__stats, .hc-topic-card__context"
                  )).map((element) => element.getBoundingClientRect().toJSON())
                    .filter((rectangle) => rectangle.width > 0 && rectangle.height > 0),
                  clientWidth: card.clientWidth,
                  scrollWidth: card.scrollWidth,
                  footerDisplay: getComputedStyle(footer).display,
                  footerAfterContent: getComputedStyle(footer, "::after").content
                };
              })
            };
          })()
        JS
      end
    end
  end
end
