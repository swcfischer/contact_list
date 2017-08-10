require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'rack'

configure do
  enable :sessions
  set :session_secret, 'secure_password'
  set :erb, :escape_html => true
end

before do
  session[:contacts] ||= {}
end

helpers do

  def selected(actual_type, type)
    if actual_type == type
    "selected"
    end
  end

  def sort_contacts(&block)
    session[:contacts].sort_by.each do |name, info|

      yield(name, info)
    end
  end
end

def name_error(input)
  input = input.strip
  if !(1..15).cover?(input.length)
    "Name must be more than one character"
  elsif session[:contacts][input]
    "This name already exists"
  else
    nil
  end
end


def number_error(input)
  number = input.strip
  numbers = number.chars.select { |num| ("0".."9").cover? num}
  if numbers.size < 7 || numbers.size > 11
    "The number you entered is invalid, check the length"
  else
    nil
  end
end

def empty_contacts
  if session[:contacts].empty?
    session[:status] = "You currently have no contacts"
  end
end

get '/' do
  empty_contacts # Shows every time since it runs on every get request
  
  @contacts = session[:contacts]
  
  erb :home, layout: :layout
end

get "/add_contact" do
  erb :add, layout: :layout
end

post "/add_contact" do
  @contacts = session[:contacts]
  first_name = params[:first_name]
  last_name = params[:last_name]
  phone = params[:phone_number]
  relation = params[:relation]

  if name_error(first_name)
    session[:error] = name_error(first_name)
    erb :add
  elsif number_error(phone)
    session[:error] = number_error(phone)
    erb :add
  else
    @contacts[first_name] = {first: first_name, last: last_name, phone: phone, relation: relation, block: false}
    redirect "/"
  end
end

get "/view/:name" do
  first_name = params[:name]
  @info = session[:contacts][first_name]

  erb :view
end

get "/edit/:name" do
  name = params[:name]
  @contacts = session[:contacts]
  @first_name = @contacts[name][:first]
  @last_name = @contacts[name][:last]
  @phone = @contacts[name][:phone]
  @relation = @contacts[name][:relation]

  erb :edit
end

post "/edit/:name" do
  name = params[:name]
  @contacts = session[:contacts]
  first_name = params[:first_name]
  last_name = params[:last_name]
  phone = params[:phone_number]
  relation = params[:relation]
  @contacts.delete(name)
  if name_error(first_name)
    session[:error] = name_error(first_name)
    erb :edit
  elsif number_error(phone)
    session[:error] = number_error(phone)
    erb :edit
  else
    @contacts[first_name] = {first: first_name, last: last_name, phone: phone, relation: relation, block: false}
    redirect "/"
  end
end

post "/:name/delete" do
  name = params[:name]

  session[:contacts].delete(name)
  session[:status] = "You have successfully deleted the contact #{name}"
  redirect "/"
end

post "/:name/block" do
  name = params[:name]
  session[:contacts][name][:block] = !session[:contacts][name][:block]
  verb = session[:contacts][name][:block] ? "blocked" : "unblocked"
  session[:status] = "You have successfully #{verb} the contact #{name}"
  redirect "/"

end
