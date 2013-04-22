class Vote
  include DataMapper::Resource

  property    :id,   Serial
  property    :vote, Integer, :required => true
  timestamps  :at
end
