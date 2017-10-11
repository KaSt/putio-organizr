class OrganizerJob
  include Import['organizer']

  def self.queue
    :organize
  end

  def self.perform(account)
    new.organize(account)
  end

  def organize(account)
    organizer.organize(account)
  end
end
