class GenerateAnswerJob < ApplicationJob
  include SalesforceGptConcern  # Include the concern here

  queue_as :default

  def perform(question_id)
    question = Question.find(question_id)

    begin
      start_time = Time.now
      question.generating!
      answer = get_generation(question.prompt)
      end_time = Time.now
  
      generation_time = end_time - start_time
  
      question.update(answer: answer, generation_time: generation_time)
      question.generated!
    rescue StandardError => e
      # TODO add more error messaging
      Rails.logger.error('Error calling Salesforce Connect GPT to generate answer.' + e.inspect)
      question.failed!
    end
  end
end
