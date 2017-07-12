#!/usr/bin/env ruby
# n0vo | @n0vothedreamer
# 
# A quick subdomain bruteforce tool because I'm sick of the alternatives

require 'resolv'
require 'thread'
require 'optparse'
require 'colorize'

#
## Options Parsing
#

@opt = {
  :list 	=> "/home/n0vo/dev/proj/ruby/dns/submap/data/prefix.lst",
  :threads	=> 36,
  :servers	=> [ '208.67.222.222', '208.67.220.220' ],
  :verbose 	=> false,
}

banner = <<-BANNER
          | |                          
 ___ _   _| |__  _ __ ___   __ _ _ __  
/ __| | | | '_ \| '_ ` _ \ / _` | '_ \ 
\__ \ |_| | |_) | | | | | | (_| | |_) |
|___/\__,_|_.__/|_| |_| |_|\__,_| .__/ 
                                | |    
                                |_|    
BANNER

banners = [
  banner.blue.bold,
  banner.red.bold,
  banner.green.bold,
  banner.yellow.bold,
  banner.magenta.bold
]

# usage
opts = OptionParser.new do |opts|
  opts.banner = banners[rand(4)]
  opts.on("-d", "--domain HOST", "Specify the domain to bruteforce", :REQUIRED)			{ |domain| @opt[:domain] = domain }
  opts.on("-l", "--list FILE", "Pick a custom wordlist. Default (data/prefix.lst)")		{ |list| @opt[:list] = list }
  opts.on("-o", "--output FILE", "File to output to") { |file| @opt[:file] = file }
  opts.on("-t", "--threads NUM", Integer, "Set the number of threads to use")			{ |threads| @opt[:threads] = threads }
  opts.on("-s", "--servers [1,2,3]", Array, "Comma separated list of servers")			{ |servers| @opt[:servers] = servers }
  opts.on("-v", "--verbose", "Verbose output") { @opt[:verbose] = true }
  opts.on("-h", "--help", "Print this help text") { puts opts; exit }
  @opt[:usage] = opts
end.parse!

# enfore required options
unless @opt.has_key? :domain
  puts @opt[:usage]
  puts ''
  puts "[!] You must specify a domain to bruteforce (-d)".light_red
  puts ''
  puts "Example:\n\truby #{$0} -d facebook.com -s 8.8.8.8 -l fierce.txt".light_red

  exit 1
end

#
## Code module
#

module SubMap
# error class
class DomainError < RuntimeError
  def initialize(msg = "An error occurred")
    super(msg)
  end
end
# DNS subdomain classs
class DNS

  def initialize(suffix, file, threads, verbose, resolvers = [])
    @suffix = suffix
    @file = file
    @threads = threads
    @verbose = verbose
    @resolvers = resolvers
  end

  def run
    list_q = Queue.new
    threads, found = [], {}
    begin # raise an error if no file was specified or file doesn't exist
      list = File.open(@file, 'r')
    rescue Errno::ENOENT, TypeError
      raise DomainError.new "Missing or incorrect wordlist specified"
    end

    # let em' know what's going on
    verbose("Checking #{@suffix.to_s.green} for wildcard addresses")
    # quit if there is wildcard matching
    unless wildcard_check.empty?
      raise DomainError.new "Wildcard matching exists. Exiting"
    end

    # optional verbosity
    verbose("Adding prefixes from #{File.basename(list).to_s.yellow} to a queue")

    # append the domain name to the prefixes and add them to a work queue
    list.each do |x| 
      # add each fqdn into the list queue
      list_q.push("#{x.chomp}.#{@suffix}")
    end

    # some more verbosity
    verbose("Using nameservers: " << "#{@resolvers*', '}".red)
    verbose("Bruteforcing #{@suffix.to_s.green} using #{@threads} threads")

    # create a pool of worker threads
    workers = (0..@threads).map do
      threads << Thread.new do
        begin
	  while task = list_q.pop(true)
	    # try to resolve the fqdn
	    resolved = resolver(task)
	    # assign the results value to a hash key unless no results
	    found[task] = resolved unless resolved.empty?
	  end
        rescue ThreadError
          # accept defeat
        end
      end # Thread.new
    end # workers.map
  
    # join the threads when done
    threads.map(&:join)
    # return the results hash
    found
  end

  def verbose(msg)
    print "[#{Time.now.to_s.split[1].magenta}] #{msg}\n" if @verbose
  end

  # single dns resolve method
  def resolver(fqdn)
    dns = Resolv.new([Resolv::DNS.new( :nameserver => @resolvers, :search => [] )])

    # attempt to get address of fqdn
    x = dns.getaddresses(fqdn)
  rescue Resolv::ResolvError
    # move on
  rescue Errno::ENETUNREACH 
    raise DomainError.new "Host #{fqdn} unreachable"
  else
    x
  end

  # method to check for wildcard matching
  def wildcard_check
    wildcard_ips = []

    # look for wildcard IP addresses
    4.times do
      # random subdomain string
      sub = (0..20).map { (65 + rand(26)).chr }.join.downcase
      random_fqdn = "#{sub}.#{@suffix}"

      # if this resolves then we have a wildcard IP
      resolved = resolver(random_fqdn)
      wildcard_ips << resolved unless resolved.empty?
    end
    # return all unique wildcard IP addresses
    # this will return an empty array if none are found
    wildcard_ips.compact.uniq
  end

end
end # module

#
## Run
#

begin
  # run main
  t1 = Time.now
  dns = SubMap::DNS.new(@opt[:domain], @opt[:list], @opt[:threads], @opt[:verbose], @opt[:servers])

  # map out the results
  results = dns.run.map { |k, v| "#{k}  =>  #{v*', '}" }

  # write to file if specified
  if @opt[:file]
    dns.verbose("Writing results to #{@opt[:file].to_s.yellow}")

    File.open(@opt[:file], 'wb') do |f|
      f.puts "# Subdomain bruteforce of #{@opt[:domain]} at #{Time.now.utc}"
      # format the results cleanly into the file
      f.puts results
    end
  end

  # no matter what the results will be printed to stdout
  results.each { |x| puts x.blue }
rescue SubMap::DomainError => e
  puts "[!] #{e}".light_red

  exit 2
rescue Interrupt
  puts " aborted!".light_red

  exit 1
end

# final run time
t2 = Time.now 
puts "\nCompleted in #{(t2 - t1).to_s[0..6]}.seconds"

