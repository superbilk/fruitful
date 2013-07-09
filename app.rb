# encoding: UTF-8
require 'bundler/setup'
Bundler.require(:default)

require "sinatra/cookies"
require "sinatra/json"
require 'securerandom'
require 'date'

Dir.glob(File.join("{lib,models,controllers,routes}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial
  register Sinatra::R18n
  helpers Sinatra::JSON
  helpers Sinatra::Cookies

  # Routes
  use Routes
  use Admin

  configure do
    set :root, File.dirname(__FILE__)
    set :haml, :format => :html5
    set :cookie_options, :expires => Time.now + 3600*24
    enable :partial_underscores
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
    R18n::I18n.default = 'en'
    cookies[:language] ||= "en"
    R18n.set(cookies[:language])
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

  get "/texts.json" do
    text = getText(cookies[:text], cookies[:language])
    cookies[:text] = text["id"]
    json text
  end

  post "/:url/vote" do |url|
    account = Account.first(:url => URI.escape(url))
    vote = Vote.new(:vote => URI.escape(params[:vote]).to_i)
    vote.account = account
    vote.save
  end

  get "/:url/graph.json" do |url|
    account = Account.first(:url => URI.escape(url))
    limit = ((URI.escape(params[:width]).to_i-200)/10).ceil
    data = Hash.new
    data["weekdayBarchart"]    = weekdayBarchartData(account)
    data["activityBarchart"]   = activityBarchartData(account)
    data["tristategraph"]      = tristategraphData(account, limit)
    data["historyLinechart"]   = historyLinechartData(account)
    # data["historyBarchart"]    = historyBarchartData(account)
    data["piechartMonth"]      = piechartData(account, 30)
    data["piechartWeek"]       = piechartData(account, 7)
    data["piechartYesterday"]  = piechartData(account, 1)
    data["piechartToday"]      = piechartData(account)
    json data
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:name => URI.escape(params[:editname]))
  end

  post "/:url/language" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:language => URI.escape(params[:language]))
    cookies[:language] = URI.escape(params[:language])
    R18n.set(URI.escape(params[:language]))
  end

  get "/:url" do |url|
    @account = Account.first(:url => URI.escape(url))
    cookies[:account] = URI.escape(url)
    cookies[:language] = @account.language
    R18n.set(@account.language)
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
    adminurl ||= PasswordGenerator.new.generate(8)
    cookies[:account] = url
    Account.create(:url => url, :name => url, :adminurl => adminurl)
  end

  def tristategraphData(account, limit)
    allvotes = Vote.all(  :account => account,
                          :order => [ :created_at.desc ],
                          # :created_at.gte => Date.today,
                          :limit => limit)

    if allvotes.empty?
      votes = [0,0,0]
    else
      votes = Array.new
      allvotes.each do |vote|
        votes << vote.vote
      end
    end
    votes
  end

  def weekdayBarchartData(account)

    if account.votes.empty? || (Date.today-account.votes.first.created_at).to_i == 0
      return [0,0,0,0,0,0,0]
    end

    dayrange = (Date.today-account.votes.first.created_at).to_i
    votes = Vote.all(:account => account, :created_at.gte => Date.today-dayrange)

    data = Hash.new { |hash, key| hash[key] = {} }

    (Date::DAYNAMES).each do |dayname|
      data[dayname][:positive] = 0
      data[dayname][:negative] = 0
      data[dayname][:zero] = 0
      data[dayname][:count] = 0
    end

    votes.each do |vote|
      case vote.vote
      when 1
        data[vote.created_at.strftime("%A")][:positive] += 1
        data[vote.created_at.strftime("%A")][:count]    += 1
      when -1
        data[vote.created_at.strftime("%A")][:negative] += 1
        data[vote.created_at.strftime("%A")][:count]    += 1
      when 0
        data[vote.created_at.strftime("%A")][:zero]     += 1
        data[vote.created_at.strftime("%A")][:count]    += 1
      end
    end

    votes = []
    data.each_value do |value|
      if value[:count] == 0
        votes << [0, 1]
      else
        votes << [ (value[:negative].to_f/value[:count].to_f*100.0).round,
                   (value[:positive].to_f/value[:count].to_f*100.0).round ]
      end
    end
    votes
  end

  def activityBarchartData(account)

    if account.votes.empty?
      return [0,0,0,0,0,0,0]
    else
      query = <<-END.unindent
        SELECT count(*)
        FROM votes
        WHERE account_id = #{account.id}
        GROUP BY strftime("%w", DATE(created_at))
      END
      data = repository(:default).adapter.select(query)
    end

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

  def historyLinechartData(account)

    if account.votes.empty?
      return [0,0,0,0,0,0,0]
    else
      query = <<-END.unindent
        SELECT count(*)
        FROM votes
        WHERE account_id = #{account.id}
        GROUP BY DATE(created_at)
      END
      data = repository(:default).adapter.select(query)
      data.reverse!
    end
  end
end

class String
  # Strip leading whitespace from each line that is the same as the
  # amount of whitespace on the first line of the string.
  # Leaves _additional_ indentation on later lines intact.
  def unindent
    gsub /^#{self[/\A\s*/]}/, ''
  end
end
