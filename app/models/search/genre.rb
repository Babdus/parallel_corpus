module Search
  class Genre
    include ActiveModel::Model

    attr_accessor :id, :name_en, :name_ka

    def attributes
      instance_values
    end
  end
end
