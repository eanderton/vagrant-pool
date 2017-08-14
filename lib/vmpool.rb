require 'bundler'

begin
  require 'vagrant'
rescue LoadError
  Bundler.require(:default, :development)
end

require 'vmpool/base'
require 'vmpool/plugin'
require 'vmpool/command'
require 'vmpool/config'
