class DailyAffirmationsJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current, model = 'llama3.2:1b')
    Rails.logger.info "Starting DailyAffirmationsJob for date: #{date} with model: #{model}"

    ollama_service = OllamaService.new
    unless ollama_service.health_check
      Rails.logger.error "Ollama service is not available"
      raise "Ollama service is unavailable"
    end

    begin
      Rails.logger.info "Calling Affirmation.generate_daily_affirmations for date: #{date} and model: #{model}"
      Affirmation.generate_daily_affirmations(model, date)
      Rails.logger.info "Successfully generated affirmations for #{date} using model: #{model}"
    rescue RuntimeError => e
      Rails.logger.error "API error during affirmation generation: #{e.message}"
      raise "Failed to generate affirmations due to API error"
    rescue => e
      Rails.logger.error "Unexpected error during affirmation generation: #{e.message}"
      raise "Failed to generate affirmations due to unexpected error"
    end
  end
end
