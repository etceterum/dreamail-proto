# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

puts "DB::Seed: Running in #{Rails.env} environment"

##########
# bitmask numbers lookup table

require 'socketry/proto'

puts "  Bitmask Value"
BitmaskValue.delete_all
BitmaskValue.benchmark("Creating Bitmask Values") do
  bit_number = 1
  1.upto(Socketry::Proto::MAX_PIECE_COUNT) do |byte_number|
    $stdout.print "    #{byte_number} / #{Socketry::Proto::MAX_PIECE_COUNT}\r"
    $stdout.flush 
    0.upto(7) do |bit_offset|
      BitmaskValue.create(
        :bit_number => bit_number,
        :byte_number => byte_number,
        :bit_value => (1 << bit_offset)
      )
      bit_number += 1
    end
  end
end
puts

##########

puts "  User"
User.delete_all
User.benchmark("Creating user records") do
  [
    { :login => 'ekarpov@gmail.com', :password => 'qwerty' },
    { :login => 'ekarpov@comcast.net', :password => 'qwerty' },
    { :login => 'ekarpov@etceterum.com', :password => 'qwerty' }
  ].each do |params|
    user = User.create(
      :login => params[:login], 
      :password => params[:password]
      )
  end
end

puts "  Connection"
User.find_by_login('ekarpov@gmail.com').connect_with!(User.find_by_login('ekarpov@comcast.net'))
User.find_by_login('ekarpov@gmail.com').connect_with!(User.find_by_login('ekarpov@etceterum.com'))
User.find_by_login('ekarpov@comcast.net').connect_with!(User.find_by_login('ekarpov@etceterum.com'))
