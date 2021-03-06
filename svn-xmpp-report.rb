#!/usr/bin/ruby

# Based on jabbersend.rb from the xmpp4r project, http://home.gna.org/xmpp4r/
# Licensed under the GPL and Ruby's license, see http://github.com/ln/xmpp4r/tree/master/LICENSE

require 'rubygems'
require 'optparse'
require 'xmpp4r'
require 'xmpp4r/client'
require 'xmpp4r/xhtml'
require 'yaml'

include Jabber


conf = YAML.load_file("mucbot.yml")

my_jid = JID.new(conf['trac-sender-jid'])
password = conf['trac-sender-password']
trac_url = conf['trac-url']

to = nil
subject = path = revision = ''

OptionParser.new do |opts|
  opts.banner = 'Usage: svn-xmpp-report.rb [options]'
  opts.separator ''
  opts.on('-s', '--subject SUBJECT', 'sets the message\'s subject') { |s| subject = s }
  opts.on('-t', '--to DESTJID', 'sets the receiver') { |t| to = JID.new(t.nil? ? conf['mucbot-jid'] : t) }
  opts.on('-r', '--rev REVISION', 'sets the svn revision number') { |r| revision = r }
  opts.on('-p', '--path PATH', 'sets the svn repository path') { |p| path = p }
  opts.on_tail('-h', '--help', 'Show this message') {
    puts opts
    exit
  }
  opts.parse!(ARGV)
end


abort "No recipient specified" unless to

['revision','path'].each do | opt |
  abort "No #{opt} specified.  See svn-xmpp-report.rb -h" if opt == ''
end

output = `svnlook -r #{revision} info #{path}`
lines = output.split("\n")
user = lines[0].chomp
# If there are 5 lines of less of commit message, we show them.  If there are more, we show 4 and a More...
if lines.length <= 8
  commit_message = lines[-1,lines.size-3]
else
  commit_message = lines[3,4]
  commit_message << "#{lines.size - 5} more lines..."
end
commit_message = commit_message.join("<br/>")
commit_message.gsub!(/#(\d+)/,"<a href=\"#{trac_url}/ticket/\\1\">#\\1</a>")
commit_message.gsub!(/r(\d+)/,"<a href=\"#{trac_url}/changeset/\\1\">r\\1</a>")
xhtml = "<a href=\"#{trac_url}/changeset/#{revision}\">r#{revision}</a> by #{user}<br/>"
xhtml += commit_message

m = Message::new(to,"HTML Trac Message").set_type(:normal).set_id('1').set_subject('trac update')
puts "#{xhtml}"
html_element = Jabber::XHTML::HTML.new(xhtml)
m.add_element(html_element)
m.set_body(html_element.to_text)

cl = Client.new(my_jid)
cl.connect
cl.auth(password)
cl.send(m)
cl.close
