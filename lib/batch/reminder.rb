require 'mysql2-cs-bind'
require 'koala'
require 'yaml'

class Reminder
  def run
    reminder(birth_day_list)
  end

  def reminder(users)
    message = "誕生日おめでとう！ \n"
    message += "誕生日と言ったら免許更新を忘れずに！  確認お願いします！ \n\n"
    message += "過去の自分より from http://birth-reminder.konboi.com"

    users.each do |user|
      graph = facebook_user(user["access_token"])
      graph.put_connections("me", "feed", :message => message)
      sleep(1)
    end
  end

  def birth_day_list
    mysql = connection

    today = Time.now
    month = today.month
    day   = today.day

   users = mysql.xquery(
      'SELECT * FROM users WHERE users.birth_day_month = ? AND users.birth_day_day = ?',
      month,
      day
    )
    users
  end

  private

  def facebook_user(token)
    Koala::Facebook::API.new(token)
  end

  def connection
    return $mysql if $mysql

    env =  ENV['ENV'] ? ENV['ENV'] : 'development'
    config = YAML.load_file(File.dirname(__FILE__) + "/../../config/database.yml")[env]

    $mysql = Mysql2::Client.new(
        :host      => config["host"],
        :port      => config["port"],
        :username  => config["username"],
        :password  => config["password"],
        :database  => config["dbname"],
        :reconnect => true,
      )
  end
end
