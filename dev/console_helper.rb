require 'pp'
require_relative 'snippet'

module ConsoleHelper
  def _cs_init
    nolog
    @__snippets = []
    @__snippets << _init_snippet(Snippet.recent.first) if Snippet.recent.first
    listen

    # require '/Users/shurik/wtracker/work_tracker'
    # include WorkTracker

    Dir["#{Rails.root}/books/**/hands/*.rb"].each {|f| require f}
  end

  def _init_snippet(snippet)
    snippet.console = self
    snippet
  end

  def listen
    listener = Listen.to(Snippet::ROOT) do |modified, added, removed|
      begin
        if modified.any?
          modified.each { |path|
            puts "MODIFID: #{path}"

            if snippet = Snippet::ALL.find {|snippet| snippet.file_name == path}
              _snip_reload snippet.name
            else
              load(path)
            end
          }
        end
      rescue Exception => e
        puts "LISTEN EXCEPTION: #{e}"
      end
    end

    listener.start
  end

  def _snip_reload(name)
    Snippet.reload name

    if idx = @__snippets.index {|snippet| snippet.name == name}
      @__snippets[idx] = _init_snippet(Snippet[name])
    end

    if @_snippet.try(:name) == name
      @_snippet = Snippet[name]
    end
  end

  def method_missing(name, *args, &block)
    if @_snippet && @_snippet.respond_to?(name)
      @_snippet.send(name, *args, &block)
    elsif @_snippet = @__snippets.find {|snippet| snippet.respond_to?(name)}
      @_snippet.send(name, *args, &block)
    elsif @_snippet = Snippet.recent.find {|snippet| snippet.respond_to?(name)}
      @__snippets.unshift _init_snippet(@_snippet)
      @_snippet.send(name, *args, &block)
    else
      super
    end
  end

  def lkp(name)
    if @_snippet && @_snippet.respond_to?(name)
      @_snippet.name
    elsif snip = @__snippets.find {|snippet| snippet.respond_to?(name)}
      snip.name
    elsif snip = Snippet.recent.find {|snippet| snippet.respond_to?(name)}
      snip.name
    end
  end

  def snip(name = nil)
    name = name.try :to_sym

    if !name && @__snippets.first
      snippet = @__snippets.first
    elsif snippet = Snippet[name]
      @__snippets.unshift snippet
    else
      snippet = Snippet.make name
    end

    system "#{ENV['EDITOR']} #{snippet.file_name}"
  end

  def snips
    @__snippets
  end

  def snames
    puts Snippet.recent.map{|snippet| snippet.name.to_s}.join("\n")
  end

  def nolog
    @_logger = ActiveRecord::Base.logger
    # ActiveRecord::Base.logger = nil
    ActiveRecord::Base.logger = Rails.logger.clone
    ActiveRecord::Base.logger = Logger.new("#{Rails.root}/log/development.log")

    if block_given?
      yield
      log
    end

    nil
  end

  def log
    ActiveRecord::Base.logger = @_logger
  end

  CONST_SHORTCUTS = {
    "DO" => 'Prob::DrawingOdds',
    'R'  => 'CardRange',
    'S'  => 'Rpeval::CardSet'
  }
  module MissingConsts
    def const_missing(name)
      name = name.to_s

      if Rpeval::CardSet.right_format?(name)
        Rpeval::CardSet.parse(name)
      elsif CardRange.right_format?(name)
        r = CardRange.parse(name)
        r.ranges.size == 1 ? r.ranges.first : r
      elsif const_name = CONST_SHORTCUTS[name]
        const_get const_name
      elsif name.size == 1 && rank = Rpeval::Rank.try_parse(name)
        rank
      else
        super
      end
    end
  end

  def r(str)
    CardRange.parse str
  end

  def f(str)
    r(str).fraction
  end

  def s(str)
    Rpeval::CardSet.parse str
  end

  # Object.extend MissingConsts

  def pe
    Rpeval::PokerEvaluation
  end
end
