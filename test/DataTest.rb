require '../app'
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

class DataTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App.new!
  end

  def test_data
    data = app.activityBarchartData(Account.first(:url => "endetrak"))
    puts data.inspect
    # puts last_response.body
  end

end
