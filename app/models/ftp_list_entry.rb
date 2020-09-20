class FtpListEntry
  def initialize(string)
    @string = string
  end

  def splitted
    @splitted ||= @string.split(/ +/)
  end

  def name
    splitted.last
  end

  def size
    splitted[4]
  end

  def date
    Date.parse splitted[5 .. 7].join(" ")
  end

  def file?
    !folder?
  end

  def folder?
    @string[0] == "d"
  end
end