class Organizer
  include Import['putio']
  include Import['shows_repository']
  include Import['logger']

  def organize(account)
    logger.info("Organize: #{account}")
    folder = maybe_create_folder('-=- TV Series -=-', access_token: account[:access_token])
    transfers = putio.list_completed_transfers(access_token: account[:access_token])
    transfers.each do |e|
      logger.debug("Transfer name: #{e[:transfer_name]}")
      s = shows_repository.find_by_title(e[:transfer_name])
      if s.nil?
        logger.debug("No match for: #{e[:transfer_name]}")
        next
      else
        logger.debug("Match found for: #{e[:transfer_name]} : #{s}")
      end
      next if ENV['DRY_RUN']
      f = maybe_create_folder(s[:title], folder[:id], access_token: account[:access_token])
      putio.move_file(e[:file_id], f[:id], access_token: account[:access_token])
    end
  end

  def maybe_create_folder(name, parent_id = 0, access_token:)
    find_folder(name, parent_id, access_token: access_token) || putio.create_folder(name, parent_id, access_token: access_token)
  end

  def find_folder(name, parent_id = 0, access_token:)
    putio.list_files(parent_id, access_token: access_token).find do |e|
      e[:name] == name
    end
  end
end
