class Admin::TextBlocksController < Admin::BaseController
  before_action :set_search_params, only: :index

  def index
    @collection = Collection.find(params[:collection_id]) unless params[:collection_id].blank?

    @text_blocks = Views::TextBlockPair.where(original_language: 0)

    %i[original_contents translation_contents].each do |field|
      unless params[field].blank?
        @text_blocks = @text_blocks.where(Views::TextBlockPair.arel_table[field].matches("%#{params[field]}%"))
      end
    end
    @text_blocks = @text_blocks.where(original_id: params[:original_id]) unless params[:original_id].blank?
    @text_blocks = @text_blocks.where(collection_id: params[:collection_id]) unless params[:collection_id].blank?
    @text_blocks = @text_blocks.order(:original_id).page(params[:page]).per(20)
  end

  def new
    @text_block = TextBlock.new
  end

  def create
    @text_block = TextBlock.find(params[:id])
  end

  def edit
    @text_block = TextBlock.find(params[:id])
  end

  def update
    @text_block = TextBlock.find(params[:id])
    if @text_block.update(text_blocks_params)
      redirect_to edit_text_blocks_admin_collection_path(id: @text_block.collection_id)
    else
      render 'admin/collections/edit_text_blocks', status: :unprocessable_entity
    end
  end

  private

  def set_search_params
    @search = Search::TextBlock.new(params.permit(:collection_id, :original_id, :original_contents, :translation_contents))
  end

  def text_blocks_params
    params.require(:text_block).permit(:contents)
  end

end
