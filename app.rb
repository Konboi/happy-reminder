require 'sinatra/base'
require 'mysql2-cs-bind'
require 'koala'
require 'erubis'
require 'yaml'

YAML::ENGINE.yamler = 'syck'

class HappyReminder < Sinatra::Base
  set :port, 8765
  set :environments, %w{development production}
  set :session, true
  set :logging, true
  set :bind, '0.0.0.0'
  set :public_folder, './root/'

  helpers do
    set :erb, :escape_html => true

    def connection
      return $mysql if $mysql
      env =  ENV['RACK_ENV']

      config = YAML.load_file(File.dirname(__FILE__) + "/config/database.yml")[env]
      $mysql = Mysql2::Client.new(
        :host      => config["host"],
        :port      => config["port"],
        :username  => config["username"],
        :password  => config["password"],
        :database  => config["dbname"],
        :reconnect => true,
      )

    end

    def facebook_app
      env =  ENV['RACK_ENV']
      config = YAML.load_file(File.dirname(__FILE__) + "/config/sns.yml")[env]["facebook"]

      return {
        app_id: config["app_id"],
        app_secret: config["app_secret"],
        callback: config["callback"],
      }
    end

    def facebook_user(oauth_access_token)
      Koala::Facebook::API.new(oauth_access_token)
    end
  end


  get '/' do
    erb :index
  end

  get '/facebook/oauth' do
    app = facebook_app
    oauth = Koala::Facebook::OAuth.new(app[:app_id], app[:app_secret], app[:callback])

    redirect oauth.url_for_oauth_code(:permissions => ["user_birthday", "publish_stream"])
  end

  get '/facebook/callback' do
    app   = facebook_app
    mysql = connection
    oauth = Koala::Facebook::OAuth.new(app[:app_id], app[:app_secret], app[:callback])

    if params[:code]
      begin
        token         = oauth.get_access_token(params[:code])
        graph         = Koala::Facebook::API.new(token).get_object("/me")
        user_birthday = graph["birthday"].split("/")
        birthday      = Time.local(user_birthday[2], user_birthday[0], user_birthday[1])

        user = mysql.xquery("SELECT * FROM users WHERE facebook_id=?", graph["id"]).first
        redirect '/complete' and return if user

        mysql.xquery(
          'INSERT INTO users (facebook_id, birth_day,  birth_day_month, birth_day_day, access_token, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          graph["id"],
          birthday,
          user_birthday[0].to_i,
          user_birthday[1].to_i,
          token,
          Time.now,
        )

        redirect 'complete'
      rescue => e
        puts e
      end

      redirect '/'
    else
      redirect '/error'
    end
  end

  get '/complete' do
    erb :complete
  end

  run! if app_file == $0
end
