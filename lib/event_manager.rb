require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone_number)
  number = phone_number.gsub(/\D/, '')
  
  if number.length == 10
    number
  elsif number.length == 11 && number[0] == '1'
    number[1..]
  else
    'wrong number'
  end
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

def frequency(hash)
  hash.max_by { |k,v| v}
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
peak_hour = Array.new()
peak_week_day = Array.new()
i = 0
week_days = { 1=>'monday', 2=>'tuesday', 3=>'wednesday', 4=>'thursday', 5=>'friday', 6=>'saturday', 7=>'sunday'}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  number = clean_phone_numbers(row[:homephone])
  puts "#{name} #{number}"

  register_date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
  peak_hour[i] = register_date.hour
  peak_week_day[i] = register_date.cwday
  i = i+1

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id,form_letter)
end
p "people are rigistered at #{frequency(peak_hour.tally)[0]}:00"
  p "the most active day is: #{week_days[frequency(peak_week_day)].capitalize}"