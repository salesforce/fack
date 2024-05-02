# frozen_string_literal: true

json.array! @libraries, partial: 'api/v1/libraries/library', as: :library
