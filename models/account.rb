class Account
  include DataMapper::Resource

  property    :id,   Serial
  property    :url,  String, :unique => true
  property    :name, String
  timestamps  :at

  has n, :votes
end
