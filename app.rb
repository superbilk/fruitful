# encoding: UTF-8
require 'bundler/setup'
Bundler.require(:default)

require "sinatra/cookies"
require 'securerandom'
require 'date'

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
    cookies[:language] ||= "en"
    @text = getText(cookies[:text], cookies[:language])
  end

  get "/" do
    createAccount() if cookies[:account].nil? || cookies[:account].empty?
    redirect to("/#{cookies[:account]}")
  end

  get "/:url/logout" do
    cookies.clear
    redirect to("/")
  end

  get "/:adminurl/raw.json" do |adminurl|
    account = Account.first(:adminurl => URI.escape(adminurl))
    raw = account.votes.all()
    raw.to_json
  end

  get "/texts.json" do
    content_type :json
    text = getText(cookies[:text], cookies[:language])
    cookies[:text] = text["id"]
    text.to_json
  end

  post "/:url/vote" do |url|
    account = Account.first(:url => URI.escape(url))
    vote = Vote.new(:vote => URI.escape(params[:vote]).to_i)
    vote.account = account
    vote.save
  end

  get "/:url/graph.json" do |url|
    content_type :json
    account = Account.first(:url => URI.escape(url))
    limit = ((URI.escape(params[:width]).to_i-180)/10).ceil
    data = Hash.new
    data["weekdayBarchart"] = weekdayBarchartData(account)
    data["tristategraph"] = tristategraphData(account, limit)
    data["piechartMonth"] = piechartData(account, 30)
    data["piechartWeek"] = piechartData(account, 7)
    data["piechartYesterday"] = piechartData(account, 1)
    data["piechartToday"] = piechartData(account)
    data.to_json
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:name => URI.escape(params[:editname]))
  end

  post "/:url/language" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:language => URI.escape(params[:language]))
    cookies[:language] = URI.escape(params[:language])
  end

  get "/:url" do |url|
    @account = Account.first(:url => URI.escape(url))
    cookies[:account] = URI.escape(url)
    cookies[:language] = @account.language
    @account = createAccount(url) if @account.nil?
    haml :index, :layout_engine => :erb
  end

private

  def getText(currentID = 0, lang = "en")
    file = File.open('./models/texts.json', "r:UTF-8")
    texts = JSON.parse(file.read)
    begin
      text = texts[lang].sample
    end while text["id"] == currentID.to_s
    return text
  end

  def createAccount(url=nil)
    cookies.clear
    url ||= PasswordGenerator.new.generate(8)
    cookies[:account] = url
    Account.create(:url => url, :name => url)
  end

  def tristategraphData(account, limit)
    allvotes = Vote.all(  :account => account,
                          :order => [ :created_at.desc ],
                          :created_at.gte => Date.today,
                          :limit => limit)
    votes = Array.new
    allvotes.each do |vote|
      votes << vote.vote
    end
    votes
  end

  def weekdayBarchartData(account)

    dayrange = (Date.today-account.votes.first.created_at).to_i

    if account.votes.empty? || dayrange == 0
      return [0,0,0,0,0,0,0]
    end

    data = Hash.new { |hash, key| hash[key] = {} }
    # (Date.today-dayrange..Date.today).each do |day|
    #   data[day.strftime("%F")][:positive] = 0
    #   data[day.strftime("%F")][:negative] = 0
    #   data[day.strftime("%F")][:zero] = 0
    #   data[day.strftime("%F")][:count] = 0
    # end

    (Date::DAYNAMES).each do |dayname|
      data[dayname][:positive] = 0
      data[dayname][:negative] = 0
      data[dayname][:zero] = 0
      data[dayname][:count] = 0
    end

    votes = Vote.all(:account => account, :created_at.gte => Date.today-dayrange)

    votes.each do |vote|
      if vote.vote == 1
        # data[vote.created_at.strftime("%F")][:positive] += 1
        # data[vote.created_at.strftime("%F")][:count] += 1
        data[vote.created_at.strftime("%A")][:positive] += 1
        data[vote.created_at.strftime("%A")][:count] += 1
      elsif vote.vote == -1
        # data[vote.created_at.strftime("%F")][:negative] += 1
        # data[vote.created_at.strftime("%F")][:count] += 1
        data[vote.created_at.strftime("%A")][:negative] += 1
        data[vote.created_at.strftime("%A")][:count] += 1
      elsif vote.vote == 0
        # data[vote.created_at.strftime("%F")][:zero] += 1
        # data[vote.created_at.strftime("%F")][:count] += 1
        data[vote.created_at.strftime("%A")][:zero] += 1
        data[vote.created_at.strftime("%A")][:count] += 1
      end
    end

    votes = []
    votes << [ (data["Monday"][:negative].to_f/data["Monday"][:count].to_f*100.0).round,
               (data["Monday"][:positive].to_f/data["Monday"][:count].to_f*100.0).round ]
    votes << [ (data["Tuesday"][:negative].to_f/data["Tuesday"][:count].to_f*100.0).round,
               (data["Tuesday"][:positive].to_f/data["Tuesday"][:count].to_f*100.0).round ]
    votes << [ (data["Wednesday"][:negative].to_f/data["Wednesday"][:count].to_f*100.0).round,
               (data["Wednesday"][:positive].to_f/data["Wednesday"][:count].to_f*100.0).round ]
    votes << [ (data["Thursday"][:negative].to_f/data["Thursday"][:count].to_f*100.0).round,
               (data["Thursday"][:positive].to_f/data["Thursday"][:count].to_f*100.0).round ]
    votes << [ (data["Friday"][:negative].to_f/data["Friday"][:count].to_f*100.0).round,
               (data["Friday"][:positive].to_f/data["Friday"][:count].to_f*100.0).round ]
    votes << [ (data["Saturday"][:negative].to_f/data["Saturday"][:count].to_f*100.0).round,
               (data["Saturday"][:positive].to_f/data["Saturday"][:count].to_f*100.0).round ]
    votes << [ (data["Sunday"][:negative].to_f/data["Sunday"][:count].to_f*100.0).round,
               (data["Sunday"][:positive].to_f/data["Sunday"][:count].to_f*100.0).round ]
    votes
  end

  def piechartData(account, daysBefore=0)
    if daysBefore==0 # today
      positive = Vote.all(:account => account, :created_at.gte => Date.today ).count(:vote.gte => 1)
      negative = Vote.all(:account => account, :created_at.gte => Date.today ).count(:vote.lte => -1)
      zero     = Vote.all(:account => account, :created_at.gte => Date.today ).count(:vote => 0)
    else
      positive = Vote.all(:account => account,
                          :created_at.lt => Date.today,
                          :created_at.gte => Date.today-(daysBefore) ).count(:vote.gte => 1)
      negative = Vote.all(:account => account,
                          :created_at.lt => Date.today,
                          :created_at.gte => Date.today-(daysBefore) ).count(:vote.lte => -1)
      zero     = Vote.all(:account => account,
                          :created_at.lt => Date.today,
                          :created_at.gte => Date.today-(daysBefore) ).count(:vote => 0)
    end
    votes = Array.new()
    votes << positive << negative << zero
    votes = [0,0,1] if (positive == 0 && negative == 0 && zero == 0)
    votes
  end
end
