require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def most_frequent_date_registered(date_stamp, dates_registered)
  if date_stamp[6] == ' '
    date_stamp.slice!(6..7)
  end
  date_stamp = date_stamp.insert(-3, '20')
  puts date_stamp
  inspect_date = Date.strptime(date_stamp, '%m/%d/%Y')

  if dates_registered[inspect_date.wday] == nil
    dates_registered[inspect_date.wday] = 1
  else
    dates_registered[inspect_date.wday] += 1
  end
end

def return_max_date(dates_registered)
  i = 0
  days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
  dates_registered.transform_keys!.with_index {|k, i| "#{days[i]}"}
  max_value = dates_registered.values.max
  puts dates_registered.select {|k, v| v == max_value}
end
def clean_phone_numbers(number)
  number.gsub!(/[\D]/, '')
  
  if number.length == 11 && number[0] == '1'
    number.slice!(0)
    number
  elsif number.length < 10 || number.length > 10
    number = '0000000000'
  else
    number
  end
end

def hour_registered(time, hours_registered)
  if hours_registered[time] == nil
     hours_registered[time] = 1
  else
    hours_registered[time] += 1
  end
end

def most_frequent(hours_registered)
  max_value = hours_registered.values.max
  puts hours_registered.select{|k, v| v == max_value}
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours_registered = {}
dates_registered = {}

contents.each do |row|
  date_stamp = row[1][0..7]
  most_frequent_date_registered(date_stamp, dates_registered)
  time_stamp = row[1][-5..-1].strip[0..1]
  hour_registered(time_stamp, hours_registered)
  number = row[5]

  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  puts clean_phone_numbers(number)
end
most_frequent(hours_registered)
return_max_date(dates_registered)
