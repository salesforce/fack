# frozen_string_literal: true

json.array! @chats, partial: 'api/v1/chats/chat', as: :chat
