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
  end
  
  def show
  end
  
  def generate_today
    if Affirmation.today.any?
      redirect_to affirmations_path, notice: "Today's affirmations already exist. Delete them first if you want to regenerate."
      return
    end
    
    begin
      DailyAffirmationsJob.perform_now
      redirect_to affirmations_path, notice: "Successfully generated today's affirmations!"
    rescue => e
      redirect_to affirmations_path, alert: "Error generating affirmations: #{e.message}"
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
  
  private
  
  def set_affirmation
    @affirmation = Affirmation.find(params[:id])
  end
end