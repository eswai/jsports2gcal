# -*- coding: UTF-8 -*-

#require 'rubygems'
require 'gcalapi'
require './jsports'
require 'yaml'

# load config file
if ARGV.size > 0 then
  config = YAML::load_file(ARGV[0])
else
  config = YAML::load_file("jsports2gcal.yaml")
end

srv = GoogleCalendar::Service.new(config["Account"], config["Password"])

config["Programs"].each_key do |key|
  puts "Start processing #{key}"
  pgconf = config["Programs"][key]

  cal = GoogleCalendar::Calendar::new(srv, pgconf["feed"])
  
  # 本日以降の予定を消去
  events = cal.events(:"max-results" => 1000, :"start-min" => Date.today)
  puts "#{events.size} items to be deleted."
  count = 1
  events.each{|e|
    begin
      e.destroy!
      sleep 0.2
    rescue => ex
      puts ex
      puts "Faild to delete #{e.title} #{e.where} #{e.st} #{e.en} "
    end
    count += 1
    puts "#{count} items done." if count % 10 == 0
  }
  
  psr = Parser.new(pgconf["uri"])
  programs = psr.acquire
  # ESPNは削除
  #programs.reject!{|pr| pr.channel =~ /ESPN/}
  
  # 予定の追加
  puts "#{programs.size} items to be added."
  count = 1
  programs.each do |pr|
    # print "#{pr.from} #{pr.to} #{pr.title}\n"
    begin
      event = cal.create_event
      event.title = pr.title.gsub(/^Cycle\*\d+[\s　]+/,'')
      event.desc = pr.uri
      event.where = pr.channel
      event.st = pr.from
      event.en = pr.to
      event.save!
    rescue => ex
      puts ex
      puts "Failed to create #{pr.title} #{pr.channel} #{pr.from} #{pr.to} "
    end
    count += 1
    puts "#{count} items done." if count % 10 == 0
  end

end