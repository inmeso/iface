# frozen_string_literal: true

require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.new do |s|
  s.name = 'iface'
  s.version = '0.1.4'
  s.date = '2017-09-28'
  s.summary = 'Configures network interfaces on Red Hat systems'
  s.authors = ['Jim Cain']
  s.email = 'camelotjim@jcain.net'
  s.files = %w[
    lib/iface.rb
    lib/iface/config.rb
    lib/iface/config_file.rb
    lib/iface/ip_address.rb
    lib/iface/ip_helpers.rb
    lib/iface/value_set.rb
  ]
  s.homepage = 'http://rubygems.org/gems/iface'
  s.license = 'BSD-3-Clause'
end

Gem::PackageTask.new(spec).define
