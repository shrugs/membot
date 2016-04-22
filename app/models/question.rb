class Question < ActiveRecord::Base
  belongs_to :thing
  belongs_to :conversation
end