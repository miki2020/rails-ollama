class Affirmation < ApplicationRecord
  validates :content, presence: true
  validates :date, presence: true

  scope :for_date, ->(date) { where(date: date) }
  scope :today, -> { for_date(Date.current) }
  scope :favorites, -> { where(favorite: true) }
  scope :by_category, ->(category) { where(category: category) }

  CATEGORIES = %w[general motivation success health relationships creativity confidence peace].freeze
  SYSTEM_PROMPT = "You are a wise and compassionate life coach who creates powerful, positive affirmations. Keep responses concise and impactful."
  def self.generate_daily_affirmations(model = 'llama3.2:1b', date = Date.current)
    raise ArgumentError, "model must be a string" unless model.is_a?(String)

    categories = CATEGORIES.sample(5)
    ollama_service = OllamaService.new

    categories.each do |category|
      begin
        prompt = build_affirmation_prompt(category)

        Rails.logger.info "Preparing API request for category: #{category}, model: #{model}, prompt: #{prompt.inspect}"
        response = ollama_service.generate(
          model: model, # Ensure model is passed as a string
          prompt: prompt,
          system: "You are a wise and compassionate life coach who creates powerful, positive affirmations. Keep responses concise and impactful."
        )

        Rails.logger.info "Response from Ollama API: #{response.inspect}"
        affirmation_text = extract_affirmation_from_response(response['response'])

        create!(
          content: affirmation_text,
          date: date,
          category: category,
          generated_prompt: prompt,
          model_used: model
        )

        # Small delay to avoid overwhelming the API
        sleep(0.5)

      rescue RuntimeError => e
        Rails.logger.error "Ollama API error for category #{category}: #{e.message}"
        Rails.logger.error "Request details: model=#{model}, prompt=#{prompt.inspect}"
        raise "Failed to generate affirmation for category #{category} due to API error"
      rescue => e
        Rails.logger.error "Unexpected error for category #{category}: #{e.message}"
        # Create a fallback affirmation
        create!(
          content: fallback_affirmation(category),
          date: date,
          category: category,
          generated_prompt: "Fallback due to unexpected error",
          model_used: 'fallback'
        )
      end
    end
  end

  private

  def self.build_affirmation_prompt(category)
    base_prompts = {
      general: "Create a concise and impactful affirmation for daily motivation and self-belief.",
      motivation: "Generate a short affirmation about taking action and achieving goals.",
      success: "Provide a brief affirmation about deserving success and abundance.",
      health: "Craft a succinct affirmation about physical and mental well-being.",
      relationships: "Write a short affirmation about healthy relationships and connection.",
      creativity: "Create a concise affirmation about creative expression and innovation.",
      confidence: "Generate a brief affirmation about self-confidence and inner strength.",
      peace: "Provide a short affirmation about inner peace and tranquility."
    }

    "#{base_prompts[category.to_sym]} Use 'I' statements. Keep it under 25 words. Return only the affirmation itself, without any additional context or explanation."
  end

  def self.extract_affirmation_from_response(response)
    # Log the full response for debugging
    Rails.logger.info "Full response: #{response.inspect}"

    # Clean up the response to get just the affirmation
    cleaned = response.strip
    # Remove any leading or trailing tags or context
    cleaned = cleaned.gsub(/<.*?>/, '')
    # Remove quotes if present
    cleaned = cleaned.gsub(/^['"]|['"]$/, '')
    # Extract the last sentence as the affirmation
    affirmation = cleaned.split('.').last&.strip || cleaned

    Rails.logger.info "Extracted affirmation: #{affirmation}"
    affirmation
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

  after_create_commit { broadcast_append_to "affirmations" }
end
