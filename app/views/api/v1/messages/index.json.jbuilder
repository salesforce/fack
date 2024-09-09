# frozen_string_literal: true

json.array! @messages, partial: 'api/v1/messages/message', as: :message