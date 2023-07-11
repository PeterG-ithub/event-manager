require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  # If the phone number is less than 10 digits, assume that it is a bad number
  # If the phone number is 10 digits, assume that it is good
  # If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
  # If the phone number is 11 digits and the first number is not 1, then it is a bad number
  # If the phone number is more than 11 digits, assume that it is a bad number

  digits_only = phone_number.gsub(/\D/, '')
  if digits_only.length < 10
    "Bad number: #{digits_only}"
  elsif digits_only.length > 11
    "Bad number: #{digits_only}"
  elsif digits_only.length == 11 && digits_only[0] != '1'
    "Bad number: #{digits_only}"
  elsif digits_only.length == 11 && digits_only[0] == '1'
    digits_only[1..10]
  else
    digits_only
  end
end

def time_targeting(reg_date, hours)
  hour = Time.strptime(reg_date, '%m/%d/%y %H:%M').hour
  hours[hour] ||= 0
  hours[hour] += 1
end

def day_targeting(reg_date, days)
  day = Date.strptime(reg_date, '%m/%d/%y %H:%M').wday
  days[day] ||= 0
  days[day] += 1
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = {}
days = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  

  hour = time_targeting(row[:regdate], hours)
  day = day_targeting(row[:regdate], days)
  # legislators = legislators_by_zipcode(zipcode)

  # p "#{name} #{zipcode} #{phone_number}"
  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)
end

p hours.max_by { |key, value| value }[0]
p Date::DAYNAMES[days.max_by { |key, value| value }[0]]
