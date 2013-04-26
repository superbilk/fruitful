class Account
  include DataMapper::Resource

  property    :id,        Serial
  property    :url,       String, :unique => true
  property    :name,      String
  property    :adminurl,  String, :unique => true
  property    :language,  String, :default => "en"
  timestamps  :at

  has n, :votes
end
