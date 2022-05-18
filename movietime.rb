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

get '/prompt' do
  @prompt = get_prompt
  haml :prompt
end

private

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

def get_prompt
  free_choice = [true, false].sample

  return {
    title: "Speak No Evil",
    description: "A world without rules and controls, without borders or boundaries. A world where anything is possible. Select any movie you please."
  } if free_choice

  prompts = [
    {
      title: "Lineage",
      description: "Explain this group to a family member, and have them select the next film.",
    },
    {
      title: "Doppelgangers",
      description: "Select a movie featuring a charactor or actor that shares your name.",
    },
    {
      title: "Travel",
      description: "Choose a film depicting the last destination you traveled to.",
    },
    {
      title: "Death of the Author",
      description: "Open a book to a random page. Select your film based on the chapter's title.",
    },
    {
      title: "Hear No Evil",
      description: "The next film mentioned to you by any person or media.",
    },
    {
      title: "Genesis",
      description: "Select a film from the same year someone close to you was born.",
    },
    {
      title: "See No Evil",
      description: "Pick a movie you have not seen starring your favorite actor.",
    },
    {
      title: "Same Same, But Different",
      description: "The title of the next movie must rhyme with the previous film.",
    },
    {
      title: "Music",
      description: "Select a movie with a soundtrack that moved you."
    }
  ]

  prompts.sample
end
