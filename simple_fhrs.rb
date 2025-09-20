# simple_fhrs.rb

# Require Dependencies
require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubi"

# Constants

FREQUENCIES_OF_INSPECTION = {
  A: "At least every six months",
  B: "At least every 12 months",
  C: "At least every 18 months",
  D: "At least every 24 months",
  E: "Alternative enforcement strategy every 3 years"
}.freeze

# Config

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

# Helper Methods

## Input Collection and Validation

def determine_missing_values(results)
  results.any? { |result| result == 666 } # "666" is the blank default value in the :start layout
end

def collect_and_transform_input

  input = [
    params[:type],
    params[:consumers],
    params[:method],
    params[:group],
    params[:hygiene],
    params[:structure],
    params[:confidence],
    params[:significance]
  ]

  input.map { |string| string.to_i } # this means I still can't use `nil` as the signifier for missing values, because I can't call `#to_i` on a `nil` object
end

## Calculations

=begin
What is the Risk Rating algorithm?
1. Sum the seven values
2. Compare the sum against the range in column 2 to calc the risk rating

What is the FHRS algorithm?
1. total the three values
2. compare the total (multiples of 5) against the table column 2 to calc the score
3. compare the highest value against the table column 3 to calc the score
4. take the lowest of the two scores as the final score
=end

def calculate_risk_rating
  puts total = @all_results.sum

  if total >= 92
    return "A"
  elsif total >= 72 && total <= 91
    return "B"
  elsif total >= 52 && total <= 71
    return "C"
  elsif total >= 31 && total <= 51
    return "D"
  elsif total <= 30
    return "E"
  end
end

def calculate_fhrs_score_from_total(total)
  if total <= 15
    return 5
  elsif total == 20
    return 4
  elsif total == 25 || total == 30
    return 3
  elsif total == 35 || total == 40
    return 2
  elsif total == 45 || total == 50
    return 1
  elsif total > 50
    return 0
  end
end

def calculate_fhrs_score_from_highest_value(highest_value)
  if highest_value > 20
    return 0
  elsif highest_value == 20
    return 1
  elsif highest_value == 15
    return 2
  elsif highest_value == 10
    return 4
  elsif highest_value == 5 || highest_value == 0
    return 5
  end
end

def calculate_food_hygiene_rating
  total = @fhrs_results.sum
  highest_value = @fhrs_results.max

  total_score = calculate_fhrs_score_from_total(total)
  highest_value_score = calculate_fhrs_score_from_highest_value(highest_value)

  [total_score, highest_value_score].min # return the lowest of the two ratings
end

# Routes

get "/" do
  erb :input
end

get "/result" do

  @all_results = collect_and_transform_input

  missing_values = determine_missing_values(@all_results) # returns true if one or more values is nil

  @fhrs_results = [
    params[:hygiene].to_i,
    params[:structure].to_i,
    params[:confidence].to_i
  ]

  if missing_values 
    session[:message] = "Sorry, one or more of the values was missing."
    redirect "/" # how to go back to a partially filled in start page?
  else
    @risk_rating = calculate_risk_rating
    @frequency = FREQUENCIES_OF_INSPECTION[@risk_rating.to_sym]
    @food_hygiene_rating = calculate_food_hygiene_rating
    erb :result
  end

end

=begin
DEVELOPMENT IDEAS
DONE
 + add the missing section!  Vulnerable persons 0/22
 + create tests in simple_fhrs_test.rb to future proof against regression
 + return a string value of inspection frequency as well as the letter score for risk rating for display in :result
 + add Eric Meyer's CSS reset to main.css
 + add my own pretty CSS to main.css
 
 FOR CONSIDERATION
 - refine CSS with Rya
 - return one of 6 images instead of/in addition to an Integer for the FHRS stars in :result
 - add validations to prevent URL parameters being manipulated? But is this really worth it?
 - find a different way of detecting a missing input value instead of "666" value
 - create more tests to test out all combinations of possible scores to ensure that the underlying logic to calculate both risk rating and FHRS scores isn't broken
=end