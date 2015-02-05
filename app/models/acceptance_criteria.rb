class AcceptanceCriteria < ActiveRecord::Base
  unloadable
  belongs_to :issue
end
