
namespace :db do
  desc "Deletes all etries in database"
  task :reset => :environment do
    puts "votes#: #{Vote.all.count}"
    puts "Deleting..."
    DataMapper.auto_migrate!
    puts "votes#: #{Vote.all.count}"
  end
end

task :environment do
  root = ::File.dirname(__FILE__)
  require ::File.join( root, 'app' )
end
