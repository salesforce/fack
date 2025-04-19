class DashboardController < ApplicationController
  def index
    @recent_questions = Question.where(user_id: current_user.id)
                                .order(created_at: :desc)
                                .limit(5)
    @recent_chats = Chat.where(user_id: current_user.id)
                        .order(created_at: :desc)
                        .limit(5)
    @recent_assistants = Assistant.joins(:chats)
                                  .where(chats: { user_id: current_user.id })
                                  .select('assistants.*, MAX(chats.created_at) as last_chat_time')
                                  .group('assistants.id')
                                  .order('last_chat_time DESC')
                                  .limit(5)
  end
end
