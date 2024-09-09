# frozen_string_literal: true

json.array! @assistants, partial: 'api/v1/assistants/assistant', as: :assistant
