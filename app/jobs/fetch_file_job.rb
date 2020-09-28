class FetchFileJob < ApplicationJob
  queue_as :default

  def perform(*args)
    file = RemoteFile.find(args.first)

    file.fetch_original
    file.create_all_types

    file.update_attributes(status: 'downloaded')
    file.symlink!
    # Do something later
  end
end
