#!/usr/bin/env ruby

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')

require 'socketry/encoder'
require 'socketry/boolean_vector'

b = Socketry::BooleanVector.new(10, true)
0.upto(b.size - 1) do |i|
  before = b.data.dup
  b[i] = false
  print "#{b.hexdata} "
  b[i] = true
  puts "- #{b.hexdata} "
end

b = Socketry::BooleanVector.new(10, false)
b[3] = true
b[8] = true
puts b.collect {|b| b ? '1' : '0' }.join('')
puts b.hexdata
c = ~b
puts c.collect {|b| b ? '1' : '0' }.join('')
puts c.hexdata

# p Socketry::Encoder.encode(b)
