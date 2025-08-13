class ApplicationController < ActionController::Base
  include Authentication
  
  def ollama_health
    service = OllamaService.new
    if service.health_check
      render plain: 'Ollama server is reachable.'
    else
      render plain: 'Ollama server is not reachable.', status: :service_unavailable
    end
  end

  def user_signed_in?
    Current.user.present?
  end

  helper_method :user_signed_in?
end
