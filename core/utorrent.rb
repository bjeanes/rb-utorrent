# rb-utorrent
# a wrapper for the utorrent webui
# Bodaniel Jeanes (12/04/08)

require 'net/http'
require 'PP'

begin
  require 'rubygems'
  require 'json'
rescue LoadError
  $stderr.puts 'This requires the JSON library. Please run "sudo gem install json"'
  abort
end

require 'lib/api'
require 'lib/settings'
require 'lib/torrents'

api = UTorrent::API.connect('192.168.0.7', '1337', 'admin', 'admin')
pp api.torrents.search("Futurama")