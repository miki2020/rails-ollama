class OllamaService
  require 'net/http'
  require 'uri'
  require 'json'

  BASE_URL = 'http://localhost:11434'

  def generate(model:, prompt:, system: nil, stream: false)
    raise ArgumentError, "model must be a string" unless model.is_a?(String)
    raise ArgumentError, "prompt must be a string" unless prompt.is_a?(String)
    raise ArgumentError, "system must be a string or nil" unless system.nil? || system.is_a?(String)

    uri = URI("#{BASE_URL}/api/generate")

    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'

    body = {
      model: model,
      prompt: prompt,
      stream: stream
    }
    body[:system] = system if system

    request.body = body.to_json

    Rails.logger.info "Sending API request: #{body.inspect}"
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.error "Ollama API error: #{response.code} - #{response.message}"
      raise "Ollama API error: #{response.code} - #{response.message}"
    end
  end

  def health_check
    uri = URI("#{BASE_URL}/api/tags")

    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    response.is_a?(Net::HTTPSuccess)
  rescue
    false
  end

  def list_models
    uri = URI("#{BASE_URL}/api/tags")

    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10
    http.open_timeout = 5

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)['models'].map { |model| model['name'] }
    else
      raise "Failed to fetch models: #{response.code} - #{response.message}"
    end
  end
end
