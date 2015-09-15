puts "EventManager initialized!"

require "csv"
require 'sunlight/congress'
require 'erb'
require 'date'

contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol).read

#helper functions

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
	Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"
	Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letter(id, form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"
	filename = "output/thanks_#{id}.html"
	File.open(filename, 'w') {|file| file.puts form_letter}
	puts "created #{filename}"
end

def generate_letters (contents)
	template_letter = File.read "form_letter.erb.html"
	erb_template = ERB.new template_letter

	contents.each do |row|
		id = row[0]
		name = row[:first_name]
		zipcode = clean_zipcode row[:zipcode]
		phone_number = clean_phone_number row[:homephone]
		legislators = legislators_by_zipcode(zipcode)
		form_letter = erb_template.result(binding)
		save_thank_you_letter(id, form_letter)
	end
end

def clean_phone_number(number)
	if number.length < 10
		"invalid number (too short)"
	elsif number.length == 10
		number
	elsif number.length == 11 && number[0] == "1"
		number[1..-1]
	else
		"invalid number (too long)"
	end
end

def find_date_mode contents, selector
	selection = contents.collect do |row|
		DateTime.strptime(row[:regdate], '%D %H').send(selector)
	end
	freq = Hash.new(0)
	selection.each {|v| freq[v] +=1}
	freq.max_by{|k,v| v}[0]
end

#executive code

generate_letters contents

puts "The most common sign-up hour is: #{find_date_mode(contents, :hour)}"

dotw = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

puts "The most common sign-up day is: #{dotw[find_date_mode(contents, :wday)]}"
