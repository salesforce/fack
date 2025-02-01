# frozen_string_literal: true

module ApplicationHelper
  def full_title(page_title = '')
    base_title = 'Fack'
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def flash_class(type)
    case type
    when 'notice'
      'bg-sky-100'
    when 'alert'
      'bg-yellow-100'
    when 'error'
      'bg-red-100'
    else
      'bg-gray-100'
    end
  end

  def show_footer?
    @show_footer != false
  end
end
