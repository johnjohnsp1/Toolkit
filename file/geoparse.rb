#!/usr/bin/env ruby
# coded by n0vo | @n0vothedreamer
# this script's main purpose is to parse log files for IP addresses, and geolocate them

# precious gems
libraries = %w( geoip socket resolv optparse colorize )

# load all the gems
libraries.each do |x| 
	begin
		require x 
	rescue LoadError => e
		puts "[!] Failed to load #{x}"
	end
end

# so I don't have to retype regex
@ipv4 = /(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}[0-9]{1,3}/

# begin options parsing
@options = {}

OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options] \r\n\r\n[options]:"
	opts.on("-t", "--target [host]", "The IP or hostname to locate") do |host|
		@options[:host] = host
	end
	opts.on("-f", "--file [file]", "Parse a file for IP addresses") do |file|
		begin
			@options[:file] = File.open(file, "r")
		rescue Errno::ENOENT
			puts "ERROR: #{file} doesn't exist!".light_red
			exit 2
		end
	end
	opts.on("-h", "--help", "Print this help text") { puts opts; exit 0 }

	@options[:usage] = opts
end.parse!

# for pretty output and such
def output(data)
	# if the target is an IP address
	if data.request =~ @ipv4
		lookup = Socket.getnameinfo(Socket.sockaddr_in(nil, data.request))[0]
	# otherwise it must be a hostname
	else
		lookup = Resolv.getaddress(data.request)
	end

	puts "\nRequest: ".bold << data.request.light_blue
	puts "Host: ".bold << lookup.light_red
	puts "City: ".bold << data.city_name.yellow
	puts "Region: ".bold << data.region_name.green
	puts "Country: ".bold << data.country_name.light_magenta
end

# run
begin
	geodb = '../data/GeoLiteCity.dat'
	# if an input logfile was specified with -f
	if @options[:file]
		# parse each line of file
		@options[:file].each do |x|
			host = x.scan(@ipv4)
			next if host.join('.') == "127.0.0.1" or 
				host.join('.') == "127.0.1.1" or 
				host.empty?
			
			data = GeoIP.new(geodb).city(host*'.')
			
			output(data)
		end
	# otherwise if the -t option was used
	else
		data = GeoIP.new(geodb).city(@options[:host])
		output(data)
	end

rescue NoMethodError
	puts @options[:usage]
	exit 2
end

