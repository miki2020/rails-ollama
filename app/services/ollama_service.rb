class OllamaService
  require 'net/http'
  require 'uri'
  require 'json'
  
  BASE_URL = 'http://localhost:11434'
  
  def generate(model:, prompt:, system: nil, stream: false)
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
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
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
  
  private
  
  def make_request(method, path, body = nil)
    uri = URI("#{BASE_URL}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 30
    http.open_timeout = 10
    
    request = case method
              when :get
                Net::HTTP::Get.new(uri)
              when :post
                Net::HTTP::Post.new(uri)
              else
                raise "Unsupported HTTP method: #{method}"
              end
    
    request['Content-Type'] = 'application/json' if body
    request.body = body.to_json if body
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "Ollama API error: #{response.code} - #{response.message}"
    end
  end
end