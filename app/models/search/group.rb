module Search
  class Group
    include ActiveModel::Model

    attr_accessor :id, :supergroup_id, :supergroup_name_ka, :name_en, :name_ka, :status

    def attributes
      instance_values
    end
  end
end
