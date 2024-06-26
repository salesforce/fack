# frozen_string_literal: true

class DocumentsQuestion < ApplicationRecord
  belongs_to :document, counter_cache: :questions_count
  belongs_to :question
end
