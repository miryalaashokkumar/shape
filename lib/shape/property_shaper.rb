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
      return if shaper_context.method_defined?(name.to_sym)
      options = self.options
      define_from do
        # Define helpers inside block for visibility
        fetch_from_hash = ->(source, key) do
          if source.respond_to?(:key?)
            return source[key.to_sym] if source.key?(key.to_sym)
            return source[key.to_s] if source.key?(key.to_s)
          end
          source[key.to_sym] || source[key.to_s]
        end
        
        fetch_value = ->(name_param, source_name_param, source) do
          source_object = (name_param == source_name_param ? source : self)
          if source_object.respond_to?(source_name_param)
            source_object.send(source_name_param)
          elsif source.respond_to?(:[])
            fetch_from_hash.call(source, source_name_param)
          else
            nil
          end
        end
        return nil unless _source
        result = fetch_value.call(name, source_name, _source)
        if !result.nil? && (with = options[:with])
          with.shape(result, parent: self)
        elsif (each_with = options[:each_with])
          each_with.shape_collection(result, parent: self, sort_by: options[:sort_by])
        else
          result
        end
      end
    end
  end
end
