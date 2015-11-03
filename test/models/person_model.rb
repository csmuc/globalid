require 'active_model'

class PersonModel
  include ActiveModel::Model
  include PreGlobalID::Identification

  attr_accessor :id

  def self.find(id)
    new id: id
  end

  def ==(other)
    id == other.try(:id)
  end
end
