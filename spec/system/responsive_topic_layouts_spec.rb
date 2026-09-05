# frozen_string_literal: true

require_relative "page_objects/components/responsive_topic_cards"

RSpec.describe "Horizon topic layouts | Responsive cards" do
  fab!(:category) { Fabricate(:category, name: "A category with a long descriptive name") }
  fab!(:tag) { Fabricate(:tag, name: "a-long-tag-for-narrow-cards") }
  fab!(:wide_image) { Fabricate(:image_upload, width: 1200, height: 400, color: "blue") }
  fab!(:portrait_image) { Fabricate(:image_upload, width: 400, height: 800, color: "green") }
  fab!(:topics) do
    3.times.map do |index|
      Fabricate(
        :topic_with_op,
        category: category,
        tags: [tag],
        created_at: 7.days.ago,
        pinned_at: index == 2 ? 7.days.ago : nil,
        pinned_globally: index == 2,
        image_upload_id: [wide_image.id, portrait_image.id, nil][index],
        title: "A long topic title that needs to wrap inside a narrow topic card #{index}",
      )
    end
  end

  fab!(:reply) { create_post(topic_id: topics.first.id, created_at: 3.days.ago) }

  let(:cards) { PageObjects::Components::ResponsiveTopicCards.new }
  let(:topic_list) { PageObjects::Components::TopicList.new }
  let!(:component) do
    horizon = RemoteTheme.import_theme_from_directory(Rails.root.join("themes/horizon"))
    horizon.update_setting(:topic_card_high_context, true)
    horizon.save!

    horizon.set_default!
    upload_theme_component(parent_theme_id: horizon.id)
  end

  def expect_cards_fit(layout, width)
    expect(cards).to have_layout(layout, count: topics.size)
    topics.each { |topic| expect(topic_list).to have_topic(topic) }
    expect(cards).to have_last_reply(topics.first)
    expect(cards).to have_pinned_topic(topics.last)
    expect(cards).to have_loaded_images(count: 2) if layout != "minimal"

    try_until_success(reason: "Wait for responsive card layout after viewport changes") do
      dimensions = cards.dimensions

      expect(dimensions["viewportWidth"]).to eq(width)
      expect(dimensions["documentWidth"]).to be <= width + 1
      expect(dimensions["gridLeft"]).to be >= -1
      expect(dimensions["gridRight"]).to be <= width + 1
      if width <= 425 && %w[gallery masonry].include?(layout)
        expect(dimensions["gapAboveGrid"]).to be > 0
      end

      dimensions["cards"].each do |card|
        expect(card["left"]).to be >= dimensions["gridLeft"] - 1
        expect(card["right"]).to be <= dimensions["gridRight"] + 1
        expect(card["scrollWidth"]).to be <= card["clientWidth"] + 1
        expect(card["footerDisplay"]).to eq("contents")
        expect(card["footerAfterContent"]).to eq("none")
        card["metadata"].each do |metadata|
          expect(metadata["left"]).to be >= card["left"] - 1
          expect(metadata["right"]).to be <= card["right"] + 1
          expect(metadata["top"]).to be >= card["top"] - 1
          expect(metadata["bottom"]).to be <= card["bottom"] + 1
        end
      end
    end
  end

  %w[gallery masonry minimal].each do |layout|
    context "with the #{layout} layout" do
      before do
        component.update_setting(:global_default_layout, layout)
        component.save!
      end

      it "keeps mobile cards inside the viewport, clear of the footer gradient and list controls",
         mobile: true do
        [360, 425].each do |width|
          page.current_window.resize_to(width, 800)
          visit("/latest")

          expect_cards_fit(layout, width)
        end
      end

      it "keeps cards contained and clear of the footer gradient when resizing desktop to mobile" do
        page.current_window.resize_to(1280, 900)
        visit("/latest")
        expect(cards).to have_layout(layout, count: topics.size)
        expect(cards).to have_loaded_images(count: 2) if layout != "minimal"
        expect(cards).to have_multicolumn_image(topics.first) if layout == "masonry"
        expect_cards_fit(layout, 1280)

        [425, 360].each do |width|
          page.current_window.resize_to(width, 800)

          expect_cards_fit(layout, width)
        end
      end
    end
  end
end
