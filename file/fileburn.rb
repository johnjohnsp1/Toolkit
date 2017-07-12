#!/usr/bin/env ruby
# n0vo | @n0vothedreamer
# small script to securely overwrite a file

require 'trollop'
require 'colorize'

# options parser
opts = Trollop::options do
	opt :file, 	"File to overwrite", :type => :string
	opt :iters, 	"Number of times to overwrite", :default => 1
	opt :delete, 	"Delete file after overwriting", :default => false
end

# run program
begin
	# get the file size
	filesize = File.size(opts[:file])
	
	# overwrite the file with pseudo-random garbage data
	File.open(opts[:file], 'wb') do |f|
		# however many iterations
		opts[:iters].times do |i|
			filesize.times { f.print(Random.rand(0xff).chr) }
			puts "[INFO] overwritten #{i + 1} times".light_blue
		end
	end	

	# delete the file if specified
	if opts[:delete]
		puts "[WARN] Deleting #{opts[:file]}".yellow
		File.delete(opts[:file]) 
	end

# in case the file doesn't exist
rescue Errno::ENOENT
	puts "[ERROR] The file #{opts[:file]} does not exist".light_red

# in case we don't know what to do
rescue TypeError
	puts "[ERROR] You must specify a file or other options. See --help for details".light_red

# in case we want to bail
rescue Interrupt
	puts " aborted!".yellow
end

