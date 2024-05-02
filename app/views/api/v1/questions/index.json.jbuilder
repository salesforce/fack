# frozen_string_literal: true

json.array! @questions, partial: 'api/v1/questions/question', as: :question
