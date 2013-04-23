require 'bundler/setup'
Bundler.require(:default)

require "sinatra/cookies"
require 'securerandom'
require './pwgen'

Dir.glob(File.join("{lib,models,controllers,routes}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial
  helpers Sinatra::Cookies

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
    if params[:url].nil? || params[:url].empty? || cookies[:account].nil? || cookies[:account].empty?
      @account = Account.new(:name => "sample user", :url => "")
    else
      @account = Account.first(:url => URI.escape(params[:url]))
    end
    cookies[:text] ||= 1
  end

  get "/" do
    if cookies[:account].nil? || cookies[:account].empty?
      newUrl = PasswordGenerator.new.generate(8)
      Account.create(:url => newUrl, :name => newUrl)
      cookies[:account] = newUrl
      redirect to("/#{newUrl}")
    else
      redirect to("/#{cookies[:account]}")
    end
  end

  get "/logout" do
    cookies[:account] = nil
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
    json = File.read('./models/texts.json')
    texts = JSON.parse(json)
    begin
      text = texts.sample
    end while text["id"] == cookies[:text].to_s
    cookies[:text] = text["id"]
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
    votes = Vote.all(:account => @account, :order => [ :created_at.desc ], :limit => limit, :created_at.lt => Time.now-15)
    @votes = Array.new
    votes.each do |vote|
      @votes << vote.vote
    end
    @votes.to_json
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => url)
    @account.update(:name => URI.escape(params[:editname]))
  end

  get "/:url" do |url|
    cookies[:account] = url
    @account = Account.first(:url => url)
    haml :index, :layout_engine => :erb
  end
end
