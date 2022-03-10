require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'bcrypt'
require 'pg'
require 'httparty'

require_relative "models/properties.rb"
enable :sessions

client_id = 'client_552b843ec0c47f69399fd5bdf5e27fff'
client_secret = 'secret_2742770f303d9d12e102773260751145'
api_key = "key_a8410ce1d9646e2ee3cb004303128d84"

get "/" do 
    erb(:index)
end

get "/search" do
    demographics = []
    # need address locator to find id and suburb shortname to search listings on domain.com.au
    suburb_locator = HTTParty.get("https://api.domain.com.au/v1/addressLocators?searchLevel=Suburb&suburb=#{params["suburb"]}&state=nsw&api_key=#{api_key}")
    if suburb_locator[0] == nil 
        redirect "/"
    end
    suburb_id = suburb_locator[0]["ids"][0]["id"]
    suburb = suburb_locator[0]["addressComponents"][0]["shortName"]
    demographics_all = HTTParty.get("https://api.domain.com.au/v1/demographics?level=Suburb&id=#{suburb_id}&api_key=#{api_key}")["demographics"]
    # retrieve desired stats from json object and send to html
    demographics_all.each_with_index do |stat, index|
        if stat["type"] == "Rent" || stat["type"] == "AgeGroupOfPopulation" || stat["type"] == "CountryOfBirth"
            demographics.push(stat)
        end
    end
    erb(:search, locals: { 
        demographics: demographics,
        suburb: suburb
    }) 
end

get "/properties/:suburb" do 
    suburb = params["suburb"]
    if suburb == "all"
        properties = get_all("properties")
    else
        properties = get("properties", "suburb", suburb)
    end
    erb(:properties, locals:{
        properties: properties,
        suburb: suburb
    })
end

get "/property/:id" do 
    property = get("properties", "property_id", params["id"]).first
    erb(:property, locals: {property: property})
end

get "/myproperties" do
    property_ids = get("favourites", "user_id", session[:user_id])
    properties = []
    property_ids.each_with_index do |property_id, index|
        current_id = get("properties","property_id", property_id["property_id"]).first 
        properties.push(current_id)
    end
    username = get("users" ,"user_id", session[:user_id]).first["username"]
    erb(:properties, locals:{
        properties: properties,
        suburb: username #properties.erb has suburb in title which will be replaced with username for myproperties
    })
end

post "/myproperties" do 
    in_database = db_query("select * from favourites where property_id = $1 and user_id = $2", [params["property_id"], session[:user_id]]).first
    if in_database == nil
        create_favourites([params["property_id"], session[:user_id]])
        erb(:bookmarked, locals: {
            suburb: params["suburb"]
        })
    else 
        redirect "/properties/#{params["suburb"]}"
    end
end

delete "/myproperties" do 
    db_query("delete from favourites where property_id = $1 and user_id = $2", [params["property_id"], session[:user_id]])
    redirect "/myproperties"
end

get "/login" do 
    erb :login
end

get "/createuser" do
    erb :createuser
end

post "/createuser" do
    username = params["username"]
    password_digest = BCrypt::Password.create(params["password"])
    adminkey = "false"
    if params["adminkey"] == "iamadmin"
        adminkey = "true"
    end
    if params["password"] == "" || params["username"] == ""
        redirect "/createuser"
    end
    in_database = get("users" ,"username", username).first
    if in_database == nil  
        create_user(username, password_digest, adminkey)
        redirect "/login"
    else 
        redirect "/createuser"
    end
end

post "/session" do 
    username = params["username"]
    password_plain = params["password"]
    user_account = get("users" ,"username", username)
    if user_account.count > 0 && BCrypt::Password.new(user_account[0]['password_digest']).==(password_plain)
        session[:user_id] = user_account[0]['user_id']
        redirect "/"
    else
        redirect "/login"
    end   
end

delete "/session" do 
    session[:user_id] = nil
    redirect "/"
end

post "/property" do 
    results = HTTParty.get("https://api.domain.com.au/v1/listings/#{params["property_id"]}?api_key=#{api_key}")
    #only insert if property not exist in database
    in_database = get("properties","property_id", results["id"]).first 
    if in_database == nil 
        createproperty(results)
        erb :added
    else 
        redirect "/"    
    end
end
