#!/usr/bin/env ruby
=begin
  Spy on a Mongo connection. Filter out housekeeping queries and their responses.
  This is not thread-safe so there should be one instance of this proxy for each
  connection you want to spy on.
=end

require 'mongo-proxy'		# gem install mongo-proxy
require 'set'
require 'trollop'

opts = Trollop::options do
  opt :client_port, 'Port for the client to connect on', :default => 27018
  opt :server_port, 'Port the server is listening on', :default => 27017
  opt :debug, 'Log all the messages'
  opt :read_only, 'Prevent any traffic that writes to the database'
end

# Filter out housekeeping traffic.
IGNORE = ["whatsmyuri", "getLog", "replSetGetStatus", "ismaster"].freeze

# Keep track of which requests are pending and only log responses to them.
pending = Set.new

# Remove options added by Trollop that would make the proxy class choke.
opts.reject! { |k| k == :help || k.to_s.end_with?('_given') }
m = MongoProxy.new(opts)

m.add_callback_to_back do |conn, msg|
  log_this = true
  msg[:query].keys.each do |k|
    if IGNORE.include? k
      log_this = false
      break
    end
  end
  if log_this
    reqId = msg[:header][:requestID]
    puts 'QUERY ' + reqId.to_s + ' ####################################'
    puts msg[:query]
    pending.add reqId
    conn.on_response do |backend, resp|
      _, msg2 = WireMongo::receive(resp)
      respId = msg2[:header][:responseTo]
      if pending.include? respId
        pending.delete respId
        puts 'REPLY ' + respId.to_s + ' ####################################'
        puts msg2[:documents]
      end
      # Pass on the response to the client.
      resp
    end
  end
  # Pass on the message to the server.
  msg
end

m.start
