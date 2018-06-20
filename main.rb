require 'pathname'
require 'pry'
system("ruby #{Pathname.pwd.join('tasks','data_extractor.rb')}")
system("ruby #{Pathname.pwd.join('tasks','linear_regression.rb')}")

binding.pry
