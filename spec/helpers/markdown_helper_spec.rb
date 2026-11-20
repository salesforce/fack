# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkdownHelper, type: :helper do
  describe '#render_markdown' do
    it 'ends a list before the following heading' do
      source = <<~MD
        1. First prerequisite
        2. Second prerequisite
        3. Third prerequisite
        4. Fourth prerequisite

        ## What ACP is

        Body text.
      MD

      html = helper.render_markdown(source)

      expect(html).to include('<h2 class="text-3xl mt-2">What ACP is</h2>')
      expect(html).not_to include('## What ACP is')
      expect(html).to include('</ol>')
      expect(html.index('</ol>')).to be < html.index('<h2')
    end

    it 'keeps a heading after a bullet list out of the previous item' do
      source = <<~MD
        - One action
        - Another action

        ## Next section
      MD

      html = helper.render_markdown(source)

      expect(html).to include('<h2 class="text-3xl mt-2">Next section</h2>')
      expect(html).not_to include('## Next section')
    end

    it 'drops leading blank lines without removing the ones that structure the document' do
      html = helper.render_markdown("\n\n# Title\n\nParagraph\n")

      expect(html).to start_with('<h1')
      expect(html).to include('<p class="mb-3 leading-7">Paragraph</p>')
    end
  end
end
