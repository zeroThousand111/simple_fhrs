# simple_fhrs_test.rb

ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../simple_fhrs"

MAX_SCORES = {
    type: "40",
    consumers: "15",
    method: "20", 
    group: "22",
    hygiene: "25",
    structure: "25",
    confidence: "30",
    significance: "20"
}

MIN_SCORES = {
    type: "0",
    consumers: "0",
    method: "0", 
    group: "0",
    hygiene: "0",
    structure: "0",
    confidence: "0",
    significance: "0"
}

MISSING_TYPE_SCORE = {
    type: "",
    consumers: "0",
    method: "0", 
    group: "0",
    hygiene: "0",
    structure: "0",
    confidence: "0",
    significance: "0"
}

TRICKY_FHRS_SCORE_2_NOT_5 = {
    type: "5",
    consumers: "5",
    method: "0", 
    group: "0",
    hygiene: "15",
    structure: "0",
    confidence: "0",
    significance: "0"
}

TRICKY_FHRS_SCORE_4_NOT_5 = {
    type: "5",
    consumers: "5",
    method: "0", 
    group: "0",
    hygiene: "0",
    structure: "10",
    confidence: "0",
    significance: "0"
}

class FHRSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def test_one_missing_value_submission
    get "/result", MISSING_TYPE_SCORE
    
    assert_equal 302, last_response.status
    assert_equal "Sorry, one or more of the values was missing. Press Restart.", session[:message]
  end

  def test_max_score
    get "/result", MAX_SCORES

    assert_equal 200, last_response.status
    assert_includes last_response.body, "A", last_response.body
    assert_includes last_response.body, "0", last_response.body
  end

  def test_min_score
    get "/result", MIN_SCORES

    assert_equal 200, last_response.status
    assert_includes last_response.body, "E", last_response.body
    assert_includes last_response.body, "5", last_response.body
  end

  def test_tricky_fhrs_score_2_not_5
    get "/result", TRICKY_FHRS_SCORE_2_NOT_5

    assert_equal 200, last_response.status

    assert_includes last_response.body, "2", last_response.body
    
  end

  def test_tricky_fhrs_score_4_not_5
    get "/result", TRICKY_FHRS_SCORE_4_NOT_5

    assert_equal 200, last_response.status

    assert_includes last_response.body, "4", last_response.body
  end

end