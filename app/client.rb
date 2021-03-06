require 'faraday'
require 'json'

module PutIo
  class Client
    include Import['logger']

    Account = Struct.new(:user_id, :username, :email)

    ClientError = Class.new(RuntimeError)

    def list_completed_transfers(access_token:)
      completed_transfers(list_events(access_token: access_token))
    end

    def create_folder(name, parent_id = 0, access_token:)
      logger.debug("create_folder: #{name}, #{parent_id}")
      rs = conn.post('/v2/files/create-folder',
                     oauth_token: access_token, name: name, parent_id: parent_id)
      raise unless rs.success?
      json = JSON.parse(rs.body, symbolize_names: true)
      json[:file]
    end

    def list_events(access_token:)
      rs = conn.get('/v2/events/list',
                    oauth_token: access_token)
      fail ClientError, "HTTP status #{rs.status}" unless rs.success?
      json = JSON.parse(rs.body, symbolize_names: true)
      json[:events]
    end

    def list_files(parent_id = 0, access_token:)
      logger.debug("list_files: #{parent_id}")
      rs = conn.get('/v2/files/list',
                    oauth_token: access_token, parent_id: parent_id)
      fail ClientError, "HTTP status #{rs.status}" unless rs.success?
      json = JSON.parse(rs.body, symbolize_names: true)
      json[:files]
    end

    def move_file(file_id, folder_id, access_token:)
      logger.debug("move_file: #{file_id}, #{folder_id}")
      rs = conn.post('/v2/files/move',
                     oauth_token: access_token, file_ids: file_id, parent_id: folder_id)
      if !rs.success?
        return false if rs.status == 404
        fail ClientError, "HTTP status #{rs.status}"
      end
      json = JSON.parse(rs.body, symbolize_names: true)
      json[:status]
    end

    def fetch_account_info(access_token:)
      rs = conn.get('/v2/account/info', oauth_token: access_token)
      fail ClientError, "HTTP status #{rs.status}" unless rs.success?
      json = JSON.parse(rs.body, symbolize_names: true)
      Account.new(json.dig(:info, :user_id), json.dig(:info, :username), json.dig(:info, :mail))
    end

    def fetch_access_token(code)
      rs = conn.get '/v2/oauth2/access_token',
                       client_id: ENV.fetch('CLIENT_ID'),
                       client_secret: ENV.fetch('CLIENT_SECRET'),
                       grant_type: 'authorization_code',
                       redirect_uri: 'https://putio-organizr.herokuapp.com/oauth',
                       code: code
      fail ClientError, "HTTP status #{rs.status}" unless rs.success?
      json = JSON.parse(rs.body, symbolize_names: true)
      json[:access_token]
    end

    def completed_transfers(events)
      events.select(&method(:transfer_completed?))
    end

    def transfer_completed?(e)
      e[:type] == 'transfer_completed'
    end

    def conn
      @conn ||= Faraday.new('https://api.put.io')
    end
  end
end
