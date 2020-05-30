# require 'pry'

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def connect
      # puts "hello, i am in actioncable connection"
      # binding.pry
      puts 'hello, i am in actioncable connection'
    end
  end
end
