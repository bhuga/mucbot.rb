#!/usr/bin/env ruby

# Based on code from the xmpp4r project, http://home.gna.org/xmpp4r/
# Licensed under the GPL, see http://github.com/ln/xmpp4r/tree/master/LICENSE

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc'
require 'xmpp4r/client'
require 'daemons/daemonize'
require 'yaml'

conf = YAML.load_file('./mucbot.yml')


user = conf['mucbot-jid']
password = conf['mucbot-jid-password']

Daemonize.daemonize

cl = Jabber::Client.new(Jabber::JID.new(user))
cl.connect
cl.auth(password)
cl.send(Jabber::Presence.new)

muc = Jabber::MUC::SimpleMUCClient.new(cl)

cl.add_message_callback do |m|
  muc.send(m) unless m.type == :error
end

puts "running..."
muc.join(conf['muc'])
muc.say("Relaying messages!")

Thread.stop

cl.close


