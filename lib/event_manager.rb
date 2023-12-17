require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

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

def hour_registered(time)
  t = Time.new
  puts time.strptime("%d/%m/%y")
  begin
    puts t
    rescue
      puts "Invalid Time!!"
    end
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

contents.each do |row|
  
  time_stamp = row[1]
  hour_registered(time_stamp)
  number = row[5]
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  puts clean_phone_numbers(number)
end