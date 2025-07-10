class Affirmation < ApplicationRecord
  validates :content, presence: true
  validates :date, presence: true
  
  scope :for_date, ->(date) { where(date: date) }
  scope :today, -> { for_date(Date.current) }
  scope :favorites, -> { where(favorite: true) }
  scope :by_category, ->(category) { where(category: category) }
  
  CATEGORIES = %w[general motivation success health relationships creativity confidence peace].freeze
  
  def self.generate_daily_affirmations(date = Date.current)
    return if for_date(date).count >= 5
    
    # Clear existing affirmations for the date
    for_date(date).destroy_all
    
    categories = CATEGORIES.sample(5)
    ollama_service = OllamaService.new
    
    categories.each do |category|
      begin
        prompt = build_affirmation_prompt(category)
        
        response = ollama_service.generate(
          model: 'llama2',
          prompt: prompt,
          system: "You are a wise and compassionate life coach who creates powerful, positive affirmations. Keep responses concise and impactful."
        )
        
        affirmation_text = extract_affirmation_from_response(response['response'])
        
        create!(
          content: affirmation_text,
          date: date,
          category: category,
          generated_prompt: prompt,
          model_used: 'llama2'
        )
        
        # Small delay to avoid overwhelming the API
        sleep(0.5)
        
      rescue => e
        Rails.logger.error "Failed to generate affirmation for #{category}: #{e.message}"
        # Create a fallback affirmation
        create!(
          content: fallback_affirmation(category),
          date: date,
          category: category,
          generated_prompt: "Fallback due to API error",
          model_used: 'fallback'
        )
      end
    end
  end
  
  private
  
  def self.build_affirmation_prompt(category)
    base_prompts = {
      general: "Create a powerful, positive affirmation for daily motivation and self-belief.",
      motivation: "Create an energizing affirmation about taking action and achieving goals.",
      success: "Create an affirmation about deserving success and abundance.",
      health: "Create an affirmation about physical and mental well-being.",
      relationships: "Create an affirmation about healthy relationships and connection.",
      creativity: "Create an affirmation about creative expression and innovation.",
      confidence: "Create an affirmation about self-confidence and inner strength.",
      peace: "Create an affirmation about inner peace and tranquility."
    }
    
    "#{base_prompts[category.to_sym]} Make it personal, using 'I' statements. Keep it under 25 words. Make it specific and actionable. Only return the affirmation itself, nothing else."
  end
  
  def self.extract_affirmation_from_response(response)
    # Clean up the response to get just the affirmation
    cleaned = response.strip
    # Remove quotes if present
    cleaned = cleaned.gsub(/^["']|["']$/, '')
    # Take only the first sentence if multiple sentences
    cleaned.split('.').first&.strip || cleaned
  end
  
  def self.fallback_affirmation(category)
    fallbacks = {
      general: "I am worthy of love, success, and happiness in all areas of my life.",
      motivation: "I have the power to create positive change in my life today.",
      success: "I attract opportunities and embrace them with confidence.",
      health: "My body and mind are strong, healthy, and resilient.",
      relationships: "I give and receive love freely and authentically.",
      creativity: "My creative energy flows freely and brings joy to others.",
      confidence: "I trust myself and my abilities to overcome any challenge.",
      peace: "I am calm, centered, and at peace with myself and the world."
    }
    
    fallbacks[category.to_sym] || fallbacks[:general]
  end
end