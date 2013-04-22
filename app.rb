require 'bundler/setup'
Bundler.require(:default)

require 'securerandom'
require './pwgen'

Dir.glob(File.join("{lib,models,controllers,routes}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial

  configure do
    set :haml, :format => :html5
    enable :partial_underscores
    # enable :logging
    enable :sessions
    set :session_secret, "43fb3pwgb3gb3"
  end

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.finalize

  configure :development, :test do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/development.sqlite3")
    DataMapper.auto_upgrade!
  end

  configure :production do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/production.sqlite3")
    DataMapper.auto_upgrade!
    disable :run, :reload
  end

  before do
    if params[:url].nil? || params[:url].empty?
      @account = Account.new(:name => "sample user", :url => "")
    else
      @account = Account.first(:url => URI.escape(params[:url]))
    end
    @session = session[:account]
  end

  get "/" do
    3.times { Vote.create(:vote => [-1, 1].sample) }
    redirect to("/#{session[:account]}") unless session[:account].nil?
    haml :index, :layout_engine => :erb
  end

  get "/logout" do
    session[:account] = nil
    redirect to("/")
  end

  post "/up" do
    vote = Vote.new(:vote => 1)
    vote.account = @account
    vote.save
  end

  post "/down" do
    vote = Vote.new(:vote => -1)
    vote.account = @account
    vote.save
  end

  get "/texts.json" do
    content_type :json
    texts = Array.new
    texts << { :question => "Have you shipped today?", :positive => "YEAH!", :negative => "not yet" }
    texts << { :question => "How is it going?", :positive => "great day", :negative => "bummer" }
    texts << { :question => "How is it going?", :positive => "awesome", :negative => "bummer" }
    texts << { :question => "build server?", :positive => "green", :negative => "red" }
    texts << { :question => "How is your day?", :positive => "sunny", :negative => "rainy" }
    text = texts.sample
    text.to_json
  end

  get "/votes_count.json" do
    content_type :json
    Vote.count.to_json
  end

  get "/accounts_count.json" do
    content_type :json
    Account.count.to_json
  end

  get "/graph.json" do
    content_type :json
    limit = (URI.escape(params[:width]).to_i/5).ceil + 3
    votes = Vote.all(:account => @account, :order => [ :created_at.desc ], :limit => limit)
    @votes = Array.new
    votes.each do |vote|
      @votes << vote.vote
    end
    @votes = @votes.drop(3)
    @votes.to_json
  end

  get "/new" do
    newUrl = PasswordGenerator.new.generate(8)
    Account.create(:url => newUrl, :name => newUrl)
    session[:account] = newUrl
    redirect to("/#{newUrl}")
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => url)
    @account.update(:name => URI.escape(params[:editname]))
  end

  get "/:url" do |url|
    @account = Account.first(:url => url)
    haml :index, :layout_engine => :erb
  end
end
