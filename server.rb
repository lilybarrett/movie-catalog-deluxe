require "sinatra"
require "pg"
require 'pry'

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do
  @actors = nil
  db_connection do |conn|
    sql_query = "SELECT id, name FROM actors ORDER BY actors.name ASC" #select ID for purpose of creating link in index.erb file
    @actors = conn.exec(sql_query)
  end
  erb :'actors/index'
end

get '/actors/:id' do #create aliases in query below to make it easier to refer to things when creating your .erb files
  @actor = nil
  db_connection do |conn|
    sql_query = "SELECT actors.id AS actor_id,
                actors.name AS actor_name,
                movies.id AS movie_id,
                movies.title AS movie_title,
                cast_members.character AS character
                FROM actors
                LEFT OUTER JOIN cast_members
                ON actors.id = cast_members.actor_id
                LEFT OUTER JOIN movies
                ON movies.id = cast_members.movie_id
                WHERE actors.id = $1"
    data = [params["id"]]
    @actor = conn.exec_params(sql_query, data)
  end
  erb :'/actors/show'
end

get '/movies' do
  @movies = nil
  db_connection do |conn|
    sql_query = "SELECT movies.id AS movie_id, movies.title AS movie_title, movies.year AS release_date, movies.rating AS movie_rating, movies.genre_id, movies.studio_id, studios.name AS studio_name, genres.name AS genre
                FROM movies
                LEFT OUTER JOIN genres ON movies.genre_id = genres.id
                LEFT OUTER JOIN studios ON movies.studio_id = studios.id"

    @movies = conn.exec(sql_query)
  end
  erb :'movies/index'
end

get '/movies/:id' do
  @movie = nil
  db_connection do |conn|
    sql_query = "SELECT actors.id AS actor_id, actors.name AS actor_name, movies.id AS movie_id, movies.title AS movie_title, movies.year AS release_date, movies.rating AS movie_rating, movies.genre_id, movies.studio_id, studios.name AS studio_name, genres.name AS genre, cast_members.actor_id AS cast_member_actor_id, cast_members.character AS character
                FROM movies
                LEFT OUTER JOIN genres ON movies.genre_id = genres.id
                LEFT OUTER JOIN studios ON movies.studio_id = studios.id
                LEFT OUTER JOIN cast_members ON cast_members.movie_id = movies.id
                LEFT OUTER JOIN actors on actors.id = cast_members.actor_id
                WHERE movies.id = $1"
    data = [params["id"]]
    @movie = conn.exec_params(sql_query, data)
  end
  erb :'/movies/show'
end
