module Search
  class Collection
    include ActiveModel::Model

    attr_accessor :id, :supergroup_name_ka, :group_id, :group_name_ka, :name_en, :name_ka, :status

    def attributes
      instance_values
    end
  end
end
