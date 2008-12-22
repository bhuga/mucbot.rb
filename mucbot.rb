#!/usr/bin/env ruby

# Based on code from the xmpp4r project, http://home.gna.org/xmpp4r/
# Licensed under the GPL, see http://github.com/ln/xmpp4r/tree/master/LICENSE

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc'
require 'xmpp4r/client'
require 'daemons/daemonize'

user = 'user@example.com'
password = 'super secret'


Daemonize.daemonize

cl = Jabber::Client.new(Jabber::JID.new(user))
cl.connect
cl.auth(password)
cl.send(Jabber::Presence.new)

muc = Jabber::MUC::SimpleMUCClient.new(cl)

cl.add_message_callback do |m|
  if (m.elements['html'])
    puts "html: #{m.elements['html']}"
  end
  if m.type != :error
    muc.send(m)
  end
end

puts "running..."
muc.join("chatroom@chat.example.com/nick")
muc.say("Relaying messages!")

Thread.stop

cl.close


