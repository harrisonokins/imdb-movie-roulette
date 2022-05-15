require 'iso8601'
require 'json'
require 'open-uri'
require 'nokogiri'
require 'sinatra'

get '/' do
  haml :index
end

get '/movie' do
  get_random_movie.to_json
end

def get_random_movie
  id = rand(2..812632)
  url = "https://www.themoviedb.org/movie/#{id}"

  begin
    movie = Nokogiri::HTML(URI.open(url))
  rescue
    return get_random_movie
  end

  # Skip movies without ratings
  rating = movie.at_css('.user_score_chart')['data-percent']
  if rating == "0.0"
    puts "No ratings were present; trying again."
    return get_random_movie
  end

  # Skip movies without posters
  if movie.at_css('.poster.no_image')
    puts "No poster found; trying again."
    return get_random_movie
  end

  # Skip documentaries and music
  excluded_genres = %w[documentary music]
  genre = movie.at_css('.genres a')
  if genre.nil? || excluded_genres.include?(genre.text.downcase)
    puts "Genre was incorrect; trying again."
    return get_random_movie
  end

  # Skip movies that are less than an hour
  duration = movie.at_css('.runtime')
  if duration.nil? || !duration.text.include?('h')
    puts "Movie was too short; trying again."
    return get_random_movie
  end

  # Skip movies without trailers
  unless movie.at_css('.play_trailer')
    puts "No trailer found; trying again."
    return get_random_movie
  end

  { url: url }
end
