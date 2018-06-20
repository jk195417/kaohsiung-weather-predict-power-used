require 'pathname'
require 'nokogiri'
require 'csv'
require_relative '../models/weather_power'

kh_nodes = []
weather_powers = []
power_used_by_monthy = {}

# load weather files, source from: https://data.gov.tw/dataset/23827
puts "\nextracting weather data..."
Pathname.pwd.join('human_preprocessed_data', 'taiwan_weather').each_child do |child_file|
  puts "\textracting weather data from #{child_file}"
  xml = File.open(child_file) { |f| Nokogiri::XML(f) }
  kh_nodes += xml.css('locationName:contains("高雄")').map(&:parent)
end

# load power files, source from: https://data.gov.tw/dataset/14135
puts "\nextracting power data..."
Pathname.pwd.join('human_preprocessed_data', 'power_used').each_child do |child_file|
  puts "\textracting power data from #{child_file}"
  filename_without_ext = File.basename(child_file, '.*') # filename is yyyy-mm
  CSV.foreach(child_file, headers: true) do |row|
    # row headers = ["郵遞區號", "行政區", "用電種類", "用戶數", "契約容量", "售電度數(當月)"]
    postal_code = row[0].to_i
    next unless postal_code >= 800 && postal_code <= 852 # target is postcode between 800 and 852
    kind = row[2].delete("\xE3\x80\x80") # remove full blank, WTF why the data included full blank
    next unless kind.match?(/^25/) # target is kind = "25綜合＆電力合計"
    power_used = row[5].delete(',').to_i # remove ',' and become a Integer
    power_used_by_monthy[filename_without_ext] = (power_used_by_monthy[filename_without_ext] || 0) + power_used
  end
end

# extract data to instances
puts "\norganizing data..."
kh_nodes.each do |node|
  date = node.parent.at_css('dataTime').content
  location = node.at_css('locationName').content
  avg_t = node.at_css('weatherElement elementName:contains("平均溫度")').parent.at_css('elementValue value').content
  max_t = node.at_css('weatherElement elementName:contains("最高溫度")').parent.at_css('elementValue value').content
  min_t = node.at_css('weatherElement elementName:contains("最低溫度")').parent.at_css('elementValue value').content
  avg_rh = node.at_css('weatherElement elementName:contains("平均相對濕度")').parent.at_css('elementValue value').content
  rain_vol = node.at_css('weatherElement elementName:contains("降水量")').parent.at_css('elementValue value').content
  weather_powers << WeatherPower.new(date, location: location, kwh: power_used_by_monthy[date], avg_t: avg_t, max_t: max_t, min_t: min_t, avg_rh: avg_rh, rain_vol: rain_vol)
end

data = weather_powers.select { |it| it.kwh > 0 }

data_saved_path = Pathname.pwd.join('data.csv')
puts "\nwriting data to #{data_saved_path}"
CSV.open(data_saved_path, "wb") do |csv|
  data.each { |row| csv << row.to_a }
end
