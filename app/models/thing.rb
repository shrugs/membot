class Thing < ActiveRecord::Base
  belongs_to :level
  serialize :columns, ActiveRecord::Coders::NestedHstore

end