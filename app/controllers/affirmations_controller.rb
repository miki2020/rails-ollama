class AffirmationsController < ApplicationController
  before_action :set_affirmation, only: [:show, :toggle_favorite, :destroy]

  def index
    @date = params[:date]&.to_date || Date.current
    @affirmations = Affirmation.for_date(@date).order(:category)
    @categories = Affirmation::CATEGORIES
    @selected_category = params[:category]

    if @selected_category.present?
      @affirmations = @affirmations.by_category(@selected_category)
    end

    @favorites = Affirmation.favorites.limit(10).order(created_at: :desc)

    begin
      @models = OllamaService.new.list_models
    rescue => e
      Rails.logger.error "Error fetching models: #{e.message}"
      @models = []
    end
  end

  def show
  end

  def generate_today
    selected_model = params[:model] || 'llama3.2:1b'
    selected_date = params[:date]&.to_date || Date.current

    if Affirmation.for_date(selected_date).any?
      redirect_to affirmations_path(date: selected_date), notice: "Affirmations for #{selected_date.strftime('%B %d, %Y')} already exist. Delete them first if you want to regenerate."
      return
    end

    begin
      DailyAffirmationsJob.perform_later(selected_date, selected_model)
      redirect_to affirmations_path(date: selected_date), notice: "Affirmation generation has been queued for #{selected_date.strftime('%B %d, %Y')} using model #{selected_model}."
    rescue => e
      redirect_to affirmations_path(date: selected_date), alert: "Error queuing affirmation generation: #{e.message}"
    end
  end

  def toggle_favorite
    @affirmation.update(favorite: !@affirmation.favorite)
    redirect_to affirmations_path, notice: "Affirmation #{@affirmation.favorite? ? 'added to' : 'removed from'} favorites"
  end

  def destroy
    @affirmation.destroy
    redirect_to affirmations_path, notice: "Affirmation deleted"
  end

  def clear_today
    Affirmation.today.destroy_all
    redirect_to affirmations_path, notice: "Today's affirmations cleared"
  end

  def debug_generate_affirmations
    begin
      Affirmation.generate_daily_affirmations
      render plain: "Affirmations generated successfully."
    rescue => e
      render plain: "Error generating affirmations: #{e.message}", status: :internal_server_error
    end
  end

  private

  def set_affirmation
    @affirmation = Affirmation.find(params[:id])
  end
end
