# frozen_string_literal: true

require 'redcarpet'
# Create a custom renderer that sets a custom class for block-quotes.
class CustomRender < Redcarpet::Render::HTML
  ESCAPE_TABLE = {
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&#39;'
  }.freeze

  def escape_html(text)
    text.gsub(/[&<>"']/) { |match| ESCAPE_TABLE[match] }
  end

  def paragraph(quote)
    %(<p class="mb-3 leading-7">#{quote.gsub("\n", '<br>')}</p>)
  end

  def link(link, _title, content)
    %(<a href="#{link}" target="_new" class="text-sky-500 hover:underline">#{content}</a>)
  end

  def codespan(quote)
    return '' if quote.nil? # Return an empty string if quote is nil

    %(<code class="text-sm bg-stone-800 rounded text-amber-200 border-stone-500 border m-1 p-1">#{escape_html(quote.gsub("\n", ''))}</code>)
  end

  def block_code(code, _language)
    %(<code class="block bg-stone-800 text-white font-light p-5 rounded whitespace-pre-line mb-3">#{escape_html(code)}</code>)
  end

  def header(title, level)
    case level
    when 1
      %(<h1 class="text-4xl mt-2">#{title}</h1>)
    when 2
      %(<h2 class="text-3xl mt-2">#{title}</h2>)
    when 3
      %(<h3 class="text-2xl mt-2">#{title}</h3>)
    end
  end

  def list_item(content, _list_type)
    %(<li class="py-2 ">#{content}</li>)
  end

  def table(header, body)
    content = <<-HTML
      <thead class="p-2 text-xl">
        #{header}
      </thead>
      <tbody class="p-2">
        #{body}
      </tbody>
    HTML

    %(<table class="text-stone-700 text-left border-separate ml-3">#{content}</table>)
  end

  def table_row(content)
    %(<tr class="text-stone-700 text-left p-2">#{content}</tr>)
  end

  def list(content, list_type)
    case list_type
    when :ordered
      %(<ol class="list-decimal list-outside pl-5">#{content}</ol>)
    when :unordered
      %(<ul class="list-disc list-outside pl-5">#{content}</ul>)
    end
  end
end

module MarkdownHelper
  def render_markdown(text)
    renderer = CustomRender.new(escape_html: true, no_images: true)
    # renderer = Redcarpet::Render::HTML.new(hard_wrap: true)

    markdown = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true, tables: true)
    markdown.render(text).html_safe
  end
end
