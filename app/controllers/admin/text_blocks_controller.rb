class Admin::TextBlocksController < Admin::BaseController
  before_action :set_search_params, only: [:index, :edit_multiple]

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
    @text_blocks = @text_blocks.order(:order_number).page(params[:page]).per(20)
  end

  def show
  end

  def new
    @text_block = TextBlock.new
  end

  def create
    last_block = TextBlock.find(params[:last_text_block_id])
    ActiveRecord::Base.transaction do
      next_blocks = TextBlock.where(collection_id: last_block.collection_id)
                             .where(language: last_block.language)
                             .where("order_number > ?", last_block.order_number)
                             .order(order_number: :desc)
      next_blocks.each do |block|
        block.increment!(:order_number, 1)
      end
      TextBlock.create!(collection_id: last_block.collection_id,
                        language: last_block.language,
                        order_number: last_block.order_number + 1
                       )
    end
    redirect_to edit_multiple_admin_text_blocks_path(collection_id: last_block.collection_id)
  end

  def edit
    @text_block = TextBlock.find(params[:id])
  end

  def update
    @text_block = TextBlock.find(params[:id])
    if @text_block.update(text_blocks_params)
      redirect_to edit_multiple_admin_text_blocks_path(collection_id: @text_block.collection_id)
    else
      render :edit_multiple, status: :unprocessable_entity
    end
  end

  def destroy
    @text_block = TextBlock.find(params[:id])
    ActiveRecord::Base.transaction do
      next_blocks = TextBlock.where(collection_id: @text_block.collection_id)
                             .where(language: @text_block.language)
                             .where("order_number > ?", @text_block.order_number)
                             .order(order_number: :asc)
      @text_block.destroy!
      next_blocks.each do |block|
        block.decrement!(:order_number, 1)
      end
      head(:ok)
    rescue
      render(json: {}, status: :unprocessable_entity)
    end
  end

  def edit_multiple
    @collection = Collection.find(params[:collection_id])
    @text_blocks = @collection.text_blocks.order(:order_number).to_a

    @anchored_block = @text_blocks.detect do |tb|
      if params[:order_number].present?
        tb.order_number == params[:order_number].to_i
      elsif params[:original_contents].present?
        tb.ka? && tb.contents&.include?(params[:original_contents])
      elsif params[:translation_contents].present?
        tb.en? && tb.contents&.include?(params[:translation_contents])
      end
    end
  end

  def merge
    @text_block = TextBlock.find(params[:id])
    ActiveRecord::Base.transaction do
      next_blocks = TextBlock.where(collection_id: @text_block.collection_id)
                             .where(language: @text_block.language)
                             .where("order_number > ?", @text_block.order_number)
                             .order(order_number: :asc)
      if next_blocks.first
        @text_block.contents = "#{@text_block.contents} #{next_blocks.first.contents}"
        @text_block.save!
        next_blocks.first.destroy!
      end
      next_blocks.each do |block|
        block.decrement!(:order_number, 1)
      end
      redirect_to edit_multiple_admin_text_blocks_path(collection_id: @text_block.collection_id)
    end
  end

  def swap
    @text_block = TextBlock.find(params[:id])
    ActiveRecord::Base.transaction do
      next_block = TextBlock.where(collection_id: @text_block.collection_id)
                             .where(language: @text_block.language)
                             .where(order_number: @text_block.order_number + 1).first
      if next_block
        @text_block.order_number = -1
        @text_block.save!
        next_block.decrement!(:order_number, 1)
        @text_block.order_number = next_block.order_number + 1
        @text_block.save!
      end
      redirect_to edit_multiple_admin_text_blocks_path(collection_id: @text_block.collection_id)
    end
  end

  def split
    @text_block = TextBlock.find(params[:id])
    ActiveRecord::Base.transaction do
      next_blocks = TextBlock.where(collection_id: @text_block.collection_id)
                             .where(language: @text_block.language)
                             .where("order_number > ?", @text_block.order_number)
                             .order(order_number: :desc)
      next_blocks.each do |block|
        block.increment!(:order_number, 1)
      end
      TextBlock.create!(collection_id: @text_block.collection_id,
                        language: @text_block.language,
                        order_number: @text_block.order_number + 1,
                        contents: params[:last_contents].strip
                       )
      @text_block.update!(contents: params[:first_contents].strip)
      head(:ok)
    rescue
      render(json: {}, status: :unprocessable_entity)
    end
  end

  def download

  end

  private

  def set_search_params
    @search = Search::TextBlock.new(params.permit(:collection_id, :original_id, :original_contents, :translation_contents, :order_number))
  end

  def text_blocks_params
    params.require(:text_block).permit(:contents)
  end

end
