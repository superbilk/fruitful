class Vote
  include DataMapper::Resource

  property    :id,   Serial
  property    :vote, Integer, :required => true
  timestamps  :at

  belongs_to :account, :required => false, :default => nil
end
