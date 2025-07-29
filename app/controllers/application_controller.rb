class ApplicationController < ActionController::Base
  def ollama_health
    service = OllamaService.new
    if service.health_check
      render plain: 'Ollama server is reachable.'
    else
      render plain: 'Ollama server is not reachable.', status: :service_unavailable
    end
  end
end
