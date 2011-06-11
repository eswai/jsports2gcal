# -*- coding: UTF-8 -*-

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'pp'
require 'nkf'
require 'date'

# 番組情報
class Program
  attr_accessor :from # 開始時間
  attr_accessor :to # 終了時間
  attr_accessor :title
  attr_accessor :channel
  attr_accessor :uri
    
  def initialize(schedule, detail, channel, uri)
    @from, @to = self.parseSchedule(schedule)
    @title = detail
    @channel = channel
    @uri = "http://www.jsports.co.jp" + (uri || "")
  end
  
  # 「11月02日 (日) 25:00 - 28:00」という表記をパース
  def parseSchedule(str)
    arr = str.gsub(" ", "").force_encoding(::Encoding::UTF_8).scan(/(\d+)月(\d+)日\(.*\)(\d+):(\d+)-(\d+):(\d+)/)[0]
    m1, d1, h1, mm1, h2, mm2 = arr.map{|e| e.to_i}
    y1 = Date.today.year
    y2 = y1
    m2 = m1
    d2 = d1
    y1, m1, d1, h1 = correct(y1, m1, d1, h1)
    y2, m2, d2, h2 = correct(y2, m2, d2, h2)
    # d2 = d1 if d2 < d1 # 終了日がおかしい場合があるので修正
    [Time.mktime(y1 , m1, d1, h1, mm1), Time.mktime(y2 , m2, d2, h2, mm2)]
  end
  
  # 25:00という記述を1:00、+1日へ直す
  def correct(year, month, day, hour)
    if month < Date.today.month then # 年明けの場合
      year += 1
    end
    if hour >= 24 then
      day += 1
      hour -= 24
    end
    getsumatsu = Date.new(year, month, -1).day
    if day > getsumatsu then
      month += 1
      day -= getsumatsu
    end
    if month > 12 then
      year += 1
      month -= 12
    end
    [year, month, day, hour]
  end
end

# J sportsの番組検索ページから放送予定を取得、パースする。
class Parser
  def initialize(uri)
    @uri = uri # 番組検索ページのURI
  end
  
  def acquire
    programs = []
    doc = Hpricot.parse(open(@uri).read.encode(::Encoding::UTF_8, :undef=>:replace))
    @result = doc.at("div#resultArea")
    @result.search("tr").each do |row|
      next unless row.at("td.bSchedule")
      programs << conv_program(row)
    end
    programs
  end
  
  def conv_program(row)
    sche = row.at("td.bSchedule").inner_text
    u = row.at("dd.DETAIL").at("a")["href"] if row.at("dd.DETAIL").at("a")
    detail = row.at("dd.DETAIL").inner_text
    chan = row.at("td.bChannel").at("img")["alt"]
    Program.new(sche, detail, chan, u)
  end

end

#psr = Parser.new("http://www.jsports.co.jp/search/sys/kensaku.cgi?Genre2=12")
#pp psr.acquire
