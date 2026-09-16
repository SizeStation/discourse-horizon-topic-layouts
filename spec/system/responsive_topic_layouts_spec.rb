# frozen_string_literal: true

require_relative "page_objects/components/responsive_topic_cards"

RSpec.describe "Horizon topic layouts | Responsive cards" do
  fab!(:category) { Fabricate(:category, name: "A category with a long descriptive name") }
  fab!(:tags) do
    %w[a-long-tag-for-narrow-cards b-second c-third d-fourth].map do |name|
      Fabricate(:tag, name: name)
    end
  end
  fab!(:wide_image) { Fabricate(:image_upload, width: 1200, height: 400, color: "blue") }
  fab!(:portrait_image) { Fabricate(:image_upload, width: 400, height: 800, color: "green") }
  fab!(:topics) do
    3.times.map do |index|
      Fabricate(
        :topic_with_op,
        category: category,
        tags: index == 1 ? [] : tags,
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

  before { SiteSetting.tags_sort_alphabetically = true }

  def expect_cards_fit(layout, width)
    expect(cards).to have_layout(layout, count: topics.size)
    topics.each { |topic| expect(topic_list).to have_topic(topic) }
    expect(cards).to have_last_reply(topics.first)
    expect(cards).to have_pinned_topic(topics.last)
    expect(cards).to have_loaded_images(count: 2) if layout != "minimal"
    if layout == "minimal"
      [topics.first, topics.last].each do |topic|
        expect(cards).to have_visible_tags(topic, tags.first(3))
        expect(cards).to have_hidden_tag(topic, tags.last)
      end
      expect(cards).to have_no_tags(topics.second)
    end

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
        expect_minimal_card_layout(card, width) if layout == "minimal"
        card["metadata"].each do |metadata|
          expect(metadata["left"]).to be >= card["left"] - 1
          expect(metadata["right"]).to be <= card["right"] + 1
          expect(metadata["top"]).to be >= card["top"] - 1
          expect(metadata["bottom"]).to be <= card["bottom"] + 1
        end
      end
    end
  end

  def expect_minimal_card_layout(card, width)
    title = card.fetch("title")
    tags = card["tags"].presence
    replies = card["replies"].presence
    activity = card.fetch("activity")
    metadata = [tags, replies, activity].compact

    if width <= 425
      metadata.each { |bounds| expect(title["bottom"]).to be <= bounds["top"] + 1 }
      expect(tags["left"]).to be < (card["left"] + card["right"]) / 2 if tags
    else
      row = [title, *metadata]
      expect(row.map { |bounds| bounds["top"] }.max).to be <
        row.map { |bounds| bounds["bottom"] }.min
      expect(title["right"]).to be <= metadata.first["left"] + 1
    end

    expect(metadata.map { |bounds| bounds["top"] }.max).to be <
      metadata.map { |bounds| bounds["bottom"] }.min
    expect(tags["right"]).to be <= (replies || activity)["left"] + 1 if tags
    expect(activity["right"]).to be_within(1).of(card["innerRight"])
    if replies
      expect(activity["left"] - replies["right"]).to be_between(0, 24)
      expect((replies["top"] + replies["bottom"]) / 2).to be_within(2).of(
        (activity["top"] + activity["bottom"]) / 2,
      )
    end
  end

  def expect_leading_topic_indicator(topic, lines: nil, clipped: false, unread_count: nil)
    if unread_count
      expect(cards).to have_unread_topic_indicator(topic, count: unread_count)
    else
      expect(cards).to have_new_topic_indicator(topic)
    end

    try_until_success(
      reason: "Wait for the leading indicator to align with the first title line",
    ) do
      dimensions = cards.title_dimensions(topic)
      card = dimensions.fetch("card")
      heading = dimensions.fetch("heading")
      title = dimensions.fetch("title")
      first_text = dimensions.fetch("textRects").first
      indicator = dimensions.fetch("indicator")
      line_height = dimensions.fetch("lineHeight")

      expect(title["height"]).to be_between(line_height - 1, line_height * 2 + 1)
      expect(title["height"]).to be_within(1).of(line_height * lines) if lines
      if clipped
        overflow = [
          dimensions["titleScrollHeight"] - dimensions["titleClientHeight"],
          dimensions["titleScrollWidth"] - dimensions["titleClientWidth"],
        ]
        expect(overflow.max).to be > 1
        expect(dimensions["titleOverflow"]).to eq("hidden")
      else
        expect(dimensions["textRects"].map { |rectangle| rectangle["top"].round }.uniq.size).to eq(
          lines,
        )
      end

      expect(indicator["width"]).to be > 0
      expect(indicator["height"]).to be > 0
      expect(title["left"] - indicator["right"]).to be_between(0, line_height)
      expect(indicator["top"]).to be < first_text["bottom"]
      expect(indicator["bottom"]).to be > first_text["top"]
      [title, indicator].each do |bounds|
        expect(bounds["left"]).to be >= heading["left"] - 1
        expect(bounds["right"]).to be <= heading["right"] + 1
        expect(bounds["top"]).to be >= heading["top"] - 1
        expect(bounds["bottom"]).to be <= heading["bottom"] + 1
      end
      expect(heading["left"]).to be >= card["left"] - 1
      expect(heading["right"]).to be <= card["right"] + 1
      expect(heading["top"]).to be >= card["top"] - 1
      expect(heading["bottom"]).to be <= card["bottom"] + 1
    end
  end

  def expect_title_without_indicator_column(topic)
    expect(cards).to have_no_topic_indicator(topic)

    try_until_success(reason: "Wait for the read title to fill the empty indicator column") do
      dimensions = cards.title_dimensions(topic)

      expect(dimensions["badges"]["width"]).to eq(0)
      expect(dimensions["badges"]["height"]).to eq(0)
      expect(dimensions["title"]["left"]).to be_within(1).of(dimensions["heading"]["left"])
    end
  end

  %w[gallery masonry].each do |layout|
    context "with leading indicators in the #{layout} layout" do
      fab!(:user) { Fabricate(:user, trust_level: 1) }
      fab!(:short_topic) do
        Fabricate(:topic_with_op, category: category, title: "Short topic title")
      end
      fab!(:wrapping_topic) do
        Fabricate(
          :topic_with_op,
          category: category,
          title: "A topic title that naturally wraps onto two lines",
        )
      end
      fab!(:clamped_topic) do
        Fabricate(
          :topic_with_op,
          category: category,
          title:
            "A long topic title that wraps onto two lines and still has enough additional words to be clamped inside the card while leaving room for the new topic indicator beside it",
        )
      end

      fab!(:single_word_topic) do
        Fabricate(:topic_with_op, category: category).tap do |topic|
          topic.title =
            "AVeryLongUnbrokenTopicTitleThatMustKeepItsLeadingNewTopicIndicatorVisibleWithoutWideningTheCard"
          # Exercise long-word layout independently of title input validation.
          topic.save!(validate: false)
        end
      end
      fab!(:read_topic) do
        Fabricate(
          :read_topic,
          current_user: user,
          category: category,
          title: "An already read topic",
        )
      end
      fab!(:unread_topic) do
        Fabricate(
          :new_reply_topic,
          current_user: user,
          category: category,
          count: 12,
          title:
            "A topic with twelve unread replies and a long title that needs more than two lines while keeping its unread count visible before the first title line",
        )
      end

      before do
        component.update_setting(:global_default_layout, layout)
        component.save!
        sign_in(user)
      end

      [true, false].each do |mobile|
        it "keeps indicators before the first title line without reserving empty columns on #{mobile ? "mobile" : "desktop resizing to mobile"}",
           mobile: mobile do
          widths = mobile ? [360, 425] : [1280, 425, 360]
          page.current_window.resize_to(widths.first, 900)
          visit("/latest")
          expect(cards).to have_layout(layout, count: topics.size + 6)
          expect(cards).to have_loaded_images(count: 2)

          widths.each do |width|
            page.current_window.resize_to(width, 900)

            expect_leading_topic_indicator(short_topic, lines: 1)
            expect_leading_topic_indicator(wrapping_topic, lines: 2)
            expect_leading_topic_indicator(clamped_topic, lines: 2, clipped: true)
            expect_leading_topic_indicator(single_word_topic, clipped: true)
            expect_leading_topic_indicator(unread_topic, lines: 2, clipped: true, unread_count: 12)
            expect_title_without_indicator_column(read_topic)
            dimensions = cards.dimensions
            expect(dimensions["viewportWidth"]).to eq(width)
            expect(dimensions["documentWidth"]).to be <= width + 1
            dimensions["cards"].each do |card|
              expect(card["left"]).to be >= dimensions["gridLeft"] - 1
              expect(card["right"]).to be <= dimensions["gridRight"] + 1
              expect(card["scrollWidth"]).to be <= card["clientWidth"] + 1
            end
          end
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
