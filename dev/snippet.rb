class Snippet
  ROOT = File.expand_path('../snippets', __FILE__)
  ERB  = ERB.new File.read File.expand_path('../snippet.erb', __FILE__)
  ALL  = []
  class_attribute :created

  def self.make(name)
    new(name).tap do |snippet|
      snippet.write
    end
  end

  def self.add(name, &block)
    new(name).tap do |snippet|
      snippet.instance_eval(&block)
      ALL.push(snippet) unless snippet.off?
    end
  end

  def self.force_loading(name)
    if !Snippet[name]
      require "#{ROOT}/#{name}.rb"
    end      
  end

  delegate :force_loading, to: "self.class"

  def self.add_clone(name, from_name, &block)
    from = Snippet[from_name]

    if !from
      require "#{ROOT}/#{from_name}.rb"
      from = Snippet[from_name]
    end      

    from.clone.tap do |snippet|
      snippet.name = name
      snippet.instance_eval(&block)
      ALL.push(snippet) unless snippet.off?
    end
  end


  def on
    @on = true
  end

  def off
    @off = true
  end

  def off?
    !@on || @off
  end

  def self.new_sublcass(name)
    const_set(name.to_s.camelize, Class.new(self, &block))
  end

  attr_reader :name, :file_name
  attr_accessor :console, :name

  def initialize(name)
    @name = name
  end

  def file_name
    File.join ROOT, "#{name}.rb"
  end

  def time
    File.ctime file_name
  end

  def write
    unless File.exists?(file_name)
      File.open(file_name, "w") {|file| file.write(ERB.result binding)}
    end
  end

  def self.load_all
    Dir["#{ROOT}/*.rb", "#{ROOT}/**/*.rb"].each do |file|
      require file
    end

    ALL
  end

  def self.recent
    ALL.sort_by(&:time).reverse
  end

  def self.reload(name)
    ALL.reject! {|snippet| snippet.name == name}
    load "#{ROOT}/#{name}.rb"
  end

  def self.[](name)
    recent.find {|snippet| snippet.name == name}
  end


  def alias_method(a, m)
    singleton_class.class_eval do
      alias_method a, m
    end
  end

  def delegate_to(what)
    mod = Module.new do
      class_eval %Q{
        def respond_to?(meth)
          super || #{what}.try(:respond_to?, meth)
        rescue
          nil
        end

        def method_missing(meth, *args, &blk)
          #{what}.send(meth, *args, &blk)
        rescue NoMethodError
          super
        end
      }
    end

    self.extend mod
  end

  def _test(name)
    @test ||= Testing::Tests.const_get(name.camelize).new(Testing::Suit.new(output: STDOUT))
  end

  def setting(key)
    DbSetting.where(key: "#{@name}.#{key}").first_or_initialize
  end

  def set(key, value)
    setting = setting key
    setting.value = value.to_json
    setting.save
  end

  def get(key)
    value = setting(key).try(:value)
    value && json(value)
  end

  def json(value)
    JSON(value)
  rescue JSON::ParserError
    JSON("[#{value}]")[0]
  end


  def accessor(*names)
    names.each do |name|
      self.instance_eval %Q{
        def #{name}
          @#{name}
        end
      }
    end
  end

  def delegate(*args)
    singleton_class.class_eval do
      delegate *args
    end
  end

  def setters(args)
    if args.is_a?(Hash)
      args.each do |name, default_value|
        def_setter name, default_value
      end
    end
  end

  def def_setter(name, default_value)
    instance_eval %Q{
      def #{name}(v = nil)
        if v.nil?
          if @#{name}.nil?
            if #{default_value.inspect}.is_a?(Symbol) && respond_to?(#{default_value.inspect})
              send(#{default_value.inspect})
            else
              #{default_value.inspect} 
            end
          else
            @#{name}
          end
        else
          @#{name} = v
        end
      end
    }
  end

  def vars(*names)
    names.mapped_to { |n| send(n) }
  end

  def defm(name, &block)
    singleton_class.send(:define_method, name, &block) 
  end

  def def_me(name, eval_string)
    instance_eval %Q{ def #{name} \n #{eval_string} \n end }
  end

  def plug_in(name, options)
    force_loading name
    Snippet[name].plugged_in self, options
  end

  attr_reader :exported_methods

  def exports(*names)
    @exported_methods ||= []
    @exported_methods.push(*names)
  end

  def parses_method(whatever = nil, &blk)
    @parsed_methods ||= []
    @parsed_methods << (whatever || blk)
  end

  def parsed_method_value(method)
    @parsed_methods.present? && @parsed_methods.each do |blk| 
      value = blk.is_a?(Symbol) ? self.send(blk, method) : blk.call(method)
      return value if value
    end

    nil
  end

  def respond_to?(method)
    super || parsed_method_value(method)
  end

  def method_missing(meth, *args, &blk)
    if s = Snippet.recent.find {|s| s.exported_methods.try(:include?, meth)}
      s.send(meth, *args, &blk)
    elsif value = parsed_method_value(meth)
      value
    else
      super
    end
  end

  def persist(*attributes)
    singleton_resource = @singleton_resource ||= begin
      klass = Class.new
      Snippet.const_set(self.name.to_s.camelize, klass)
      klass.class_eval { stored_singleton }
      klass
    end

    attributes.each do |key|
      if self.respond_to?(key)
        self.singleton_class.class_eval { alias_method(:"#{key}__", key) }
      end

      singleton_class.send(:define_method, key) do |*args|
        recalc = args.size > 0 && args.last == true

        inst = singleton_resource.instance

        if (stored_value = inst[key]) && !recalc
          stored_value
        else
          new_value = self.send(:"#{key}__")
          inst[key] = new_value
          inst.save
          new_value
        end
      end
    end
  end

  def reset
  end

  load_all
  # [
  #   :real_acc_bot
  # ].each do |name|
  #   reload(name)
  # end
end
