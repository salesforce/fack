class DashboardController < ApplicationController
  def index
    @recent_questions = Question.order(created_at: :desc).limit(5)
    @recent_chats = Chat.order(created_at: :desc).limit(5)
    @recent_assistants = Assistant.joins(:chats)
                                  .select('assistants.*, MAX(chats.created_at) as last_chat_time')
                                  .group('assistants.id')
                                  .order('last_chat_time DESC')
                                  .limit(5)
  end
end
