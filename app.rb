class App < Sinatra::Base
  register Sinatra::Partial

  configure do
    set :haml, :format => :html5
    enable :partial_underscores
    enable :logging
    enable :sessions
  end

  get "/" do
    haml :index, :layout_engine => :erb
  end

end
