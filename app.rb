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
    enable :sessions
    set :session_secret, "43fb3pwgb3gb3"
    set(:cookie_options) do
      { :expires => Time.now + 3600*24*90, :expire_after => 2592000 }
    end
  end

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.finalize

  configure :development, :test do
    # enable :logging, :dump_errors, :raise_errors
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/development.sqlite3")
    DataMapper.auto_upgrade!
  end

  configure :production do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/production.sqlite3")
    DataMapper.auto_upgrade!
    disable :run, :reload
  end

  before do
    cookies[:text] ||= 1
  end

  get "/" do
    createAccount() if cookies[:account].nil? || cookies[:account].empty?
    redirect to("/#{cookies[:account]}")
  end

  get "/:url/logout" do
    cookies[:account] = nil
    redirect to("/")
  end

  get "/texts.json" do
    content_type :json
    text = getText(cookies[:text].to_s)
    cookies[:text] = text["id"]
    text.to_json
  end

  post "/:url/up" do |url|
    @account = Account.first(:url => URI.escape(url))
    vote = Vote.new(:vote => 1)
    vote.account = @account
    vote.save
  end

  post "/:url/down" do |url|
    @account = Account.first(:url => URI.escape(url))
    vote = Vote.new(:vote => -1)
    vote.account = @account
    vote.save
  end

  get "/:url/graph.json" do |url|
    content_type :json
    @account = Account.first(:url => URI.escape(url))
    limit = ((URI.escape(params[:width]).to_i-105)/9).ceil
    votes = Vote.all( :account => @account,
                      :order => [ :created_at.desc ],
                      :limit => limit)
    @votes = Array.new
    votes.each do |vote|
      @votes << vote.vote
    end
    @votes.to_json
  end

  get "/:url/piechart.json" do |url|
    content_type :json
    timeframe = URI.escape(params[:timeframe]).to_i
    @account = Account.first(:url => URI.escape(url))
    positive = Vote.all(:account => @account,
                        :created_at.gte => Time.now-timeframe)
                .count(:vote => 1)
    negative = Vote.all(:account => @account,
                        :created_at.gte => Time.now-timeframe)
                .count(:vote => -1)
    @votes = Array.new()
    @votes << positive << negative
    @votes.to_json
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:name => URI.escape(params[:editname]))
  end

  get "/:url" do |url|
    @account = Account.first(:url => URI.escape(url))
    cookies[:account] = URI.escape(url)
    @account = createAccount(url) if @account.nil?
    haml :index, :layout_engine => :erb
  end

private

  def getText(currentID = 1)
    json = File.read('./models/texts.json')
    texts = JSON.parse(json)
    begin
      text = texts.sample
    end while text["id"] == currentID
    return text
  end

  def createAccount(url=nil)
    url ||= PasswordGenerator.new.generate(8)
    cookies[:account] = url
    Account.create(:url => url, :name => url)
  end
end
