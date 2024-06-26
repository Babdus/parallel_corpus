class Admin::TranslatorsController < Admin::BaseController
  before_action :set_search_params, only: :index
  before_action :require_admin_or_superadmin, only: [:destroy]

  def index
    @translators = Translator.all

    %i[name_en name_ka].each do |field|
      unless params[field].blank?
        @translators = @translators.where(Translator.arel_table[field].matches("%#{params[field]}%"))
      end
    end
    @translators = @translators.where(id: params[:id]) unless params[:id].blank?
    @translators = @translators.order(:name_ka).page(params[:page]).per(20)
  end

  def new
    @translator = Translator.new
  end

  def create
    @translator = Translator.new(translator_params)
    if @translator.save
      redirect_to admin_translators_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @translator = Translator.find(params[:id])
  end

  def update
    @translator = Translator.find(params[:id])
    if @translator.update(translator_params)
      redirect_to admin_translators_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @translator = Translator.find(params[:id])
    if @translator.destroy!
      head(:ok)
    else
      render(json: {}, status: :unprocessable_entity)
    end
  end

  private

  def set_search_params
    @search = Search::Translator.new(params.permit(:id, :name_ka, :name_en))
  end

  def translator_params
    params.require(:translator).permit(:name_ka, :name_en)
  end

end
