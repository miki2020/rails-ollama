class DailyAffirmationsJob < ApplicationJob
  queue_as :default
  
  def perform(date = Date.current)
    Rails.logger.info "Generating daily affirmations for #{date}"
    
    # Check if Ollama is running
    ollama_service = OllamaService.new
    unless ollama_service.health_check
      Rails.logger.error "Ollama service is not available"
      return
    end
    
    Affirmation.generate_daily_affirmations(date)
    Rails.logger.info "Successfully generated affirmations for #{date}"
  end
end