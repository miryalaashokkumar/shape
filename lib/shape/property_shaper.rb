module Shape
  # = Property Shaper
  # Keeps track of property info and context
  # when shaping views.
  #
  # We'll use the PropertyShaper objects
  # later to recursively build the data.
  #
  # Allows anything inside a property block
  # to call methods in the context of the
  # Shape dsl allowing for nested properties.
  #
  # Example:
  #
  #   property :address do
  #     property :street_address do
  #       property :addr_line1
  #       property :addr_line2
  #     end
  #     property :city
  #     # ...
  #   end
  class PropertyShaper
    include Shape::Base::ClassMethods
    
    attr_accessor :name
    attr_accessor :shaper_context
    attr_accessor :options
    
    def initialize(shaper_context, name, options={}, &block)
      self.shaper_context = shaper_context
      self.name = name
      self.options = options
      
      if block
        instance_eval(&block)
      else
        from = options[:from] || name
        define_accessor(name, from)
        delegate_property(from)
      end
    end
    
    def from(&block)
      if with = options[:with]
        define_from do
          with.shape(instance_eval(&block))
        end
      else
        define_from(&block)
      end
    end
    
    def define_from(&block)
      unless shaper_context.method_defined?(name.to_sym)
        shaper_context.send(:define_method, name, &block)
      end
    end
    
    def with(&block)
      define_block(:with, &block)
    end
    
    def each_with(&block)
      define_block(:each_with, &block)
    end
    
    protected
    
    def define_block(type, &block)
      options[type] = Class.new do
        include Shape
        instance_eval(&block)
      end
      define_accessor(name, options[:from] || name)
    end
    
    def define_accessor(name, source_name)
      if !shaper_context.method_defined?(name.to_sym)
        _options = self.options
        self.define_from do
          return nil unless _source
          result = begin
                     _source_object = (name == source_name ? _source : self)
                     if _source_object.respond_to?(source_name)
                       _source_object.send(source_name)
                     elsif _source.respond_to?(:[])
                       if _source.respond_to?(:key?)
                         if _source.key?(source_name.to_sym)
                           _source[source_name.to_sym]
                         elsif _source.key?(source_name.to_s)
                           _source[source_name.to_s]
                         end
                       else
                         _source[source_name.to_sym] || _source[source_name.to_s]
                       end
                     else
                       nil
                     end
                   end
          
          if !result.nil? && with = _options[:with]
            with.shape(result, parent: self)
          elsif each_with = _options[:each_with]
            each_with.shape_collection(result, parent: self, sort_by: _options[:sort_by])
          else
            result
          end
        end
      end
    end
  end
end
