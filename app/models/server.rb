require 'net/ftp'

class Server < ApplicationRecord
  DEFAULT = 'ftp2.rbc.ru'

  def self.default
    where(domain: DEFAULT).first_or_create
  end

  def password
  end

  def credentials
    Rails.application.credentials[:ftp].find do |cred|
      cred[:server] == domain
    end
  end

  def login
    credentials[:login]
  end

  def password
    credentials[:password]
  end

  def ftp_connections
    @@ftp_connections ||= {}
  end

  def ftp
    ftp_connections[domain] = nil if ftp_connections[domain].try(:closed?)
    ftp_connections[domain] ||= new_ftp_connection
  end

  def new_ftp_connection
    ftp = Net::FTP.new domain
    ftp.passive = true
    ftp.login login, password
    ftp
  end
end
