class Admin::AuthorsController < Admin::BaseController
  before_action :set_search_params, only: :index
  before_action :require_admin_or_superadmin, only: [:destroy]

  def index
    @authors = Author.all

    %i[name_en name_ka].each do |field|
      unless params[field].blank?
        @authors = @authors.where(Author.arel_table[field].matches("%#{params[field]}%"))
      end
    end
    @authors = @authors.where(id: params[:id]) unless params[:id].blank?
    @authors = @authors.order(:name_ka).page(params[:page]).per(20)
  end

  def new
    @author = Author.new
  end

  def create
    @author = Author.new(author_params)
    if @author.save
      redirect_to admin_authors_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @author = Author.find(params[:id])
  end

  def update
    @author = Author.find(params[:id])
    if @author.update(author_params)
      redirect_to admin_authors_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @author = Author.find(params[:id])
    if @author.destroy!
      head(:ok)
    else
      render(json: {}, status: :unprocessable_entity)
    end
  end

  private

  def set_search_params
    @search = Search::Author.new(params.permit(:id, :name_ka, :name_en))
  end

  def author_params
    params.require(:author).permit(:name_ka, :name_en)
  end

end
