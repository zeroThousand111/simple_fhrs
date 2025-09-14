# simple_fhrs_test.rb

ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../simple_fhrs"

class FHRSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end





end