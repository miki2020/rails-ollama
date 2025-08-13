class AffirmationsController < ApplicationController
  before_action :require_authentication  
  before_action :set_affirmation, only: [:show, :toggle_favorite, :destroy]
  before_action :set_affirmations, only: [:index, :generate_today, :clear_today, :clear_day]

  def index
    @date = params[:date]&.to_date || Date.current
    @affirmations = @affirmations.for_date(@date).order(:category)
    @categories = Affirmation::CATEGORIES
    @selected_category = params[:category]
    @current_user = Current.user

    if @selected_category.present?
      @affirmations = @affirmations.by_category(@selected_category)
    end

    @favorites = @affirmations.favorites.limit(10).order(created_at: :desc)

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
    available_models = OllamaService.new.list_models
    selected_model = params[:model].presence_in(available_models) || available_models.first
    selected_date = params[:date]&.to_date || Date.current

    if @affirmations.for_date(selected_date).any?
      redirect_to affirmations_path(date: selected_date), notice: "Affirmations for #{selected_date.strftime('%B %d, %Y')} already exist. Delete them first if you want to regenerate."
      return
    end

    begin
      DailyAffirmationsJob.perform_later(selected_date, selected_model, Current.user.id)
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
    @affirmations.today.destroy_all
    redirect_to affirmations_path, notice: "Today's affirmations cleared"
  end

  def clear_day
    date = params[:date]&.to_date || Date.current
    Affirmation.for_date(date).destroy_all
    redirect_to affirmations_path(date: date), notice: "Affirmations for #{date.strftime('%B %d, %Y')} cleared"
  end

  private

  def set_affirmation
    @affirmation = Current.user.affirmations.find(params[:id])
  end

  def set_affirmations
    @affirmations = Current.user.affirmations.order(date: :desc)
  end
end
