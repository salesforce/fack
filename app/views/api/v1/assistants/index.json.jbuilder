# frozen_string_literal: true

json.array! @documents, partial: 'api/v1/documents/document', as: :document
