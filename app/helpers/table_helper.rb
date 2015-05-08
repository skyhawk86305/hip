module TableHelper

  # Helper for rendering a table for a collection.
  # Use it like so:
  # 
  #   <%= table_for(@collection) do |t|
  #         # t.no_header # to disable the table header
  #         t.field('column title', 'string') # preset string
  #         t.field('symbol column', :symbol) # symbol is sent to each item in the collection, or indexed by symbol if each item is a Hash
  #         t.field('block column') do {|item| link_to(item.name, item_path(item)) } # or give it a block
  #       end
  #   %>
  # 
  def table_for(collection, options = {}, &blk)
    CollectionTable.new(collection, self, options, &blk).to_table
  end

  class CollectionTable

    def initialize(collection, view_context, options = {}, &blk)
      @collection = collection
      @template = view_context
      @options = {:class_base => ''}.merge(options)
      yield self
    end

    def to_table
      class_base = @options[:class_base]
      if class_base != ''
        class_table = {:class => "#{class_base}_table"}
        class_tr = {:class => "#{class_base}_table_tr"}
        class_tr_cycle = ["#{class_base}_table_even", "#{class_base}_table_odd"]
        class_th = {:class => "#{class_base}_table_th"}
        class_td = {:class => "#{class_base}_table_td"}
      else
        class_table = {}
        class_tr = {}
        class_tr_cycle = ["even", "odd"]
        class_th = {}
        class_td = {}
      end

      content_tag('table', class_table.merge(@options[:table_options] || {})) do
        table_contents = ''  
        if header?
          table_contents << content_tag('tr', class_tr.merge(@options[:tr_options] || {})) do
            fields.map{|name, value| content_tag('th', name, class_th.merge(@options[:th_options] || {}))}
            end
        end

        if collection.empty?
          table_contents << content_tag("tr", class_tr.merge(@options[:tr_options] || {})) do
            content_tag("td", "No results", {:colspan => fields.size}.merge(class_td || {}).merge(@options[:td_options] || {}))
          end
        else
          collection.each do |item|
            table_contents << content_tag('tr', {:class => cycle(*class_tr_cycle)}.merge(@options[:tr_options] || {})) do
              fields.map { |name, value| content_tag('td', value_for_field(value, item), class_td.merge(@options[:td_options] || {})) }
            end # content_tag do
          end # each do
        end #else
        table_contents
      end # content_tag do
    end

    # thanks to bruce williams for this trick
    def method_missing(meth, *args, &block) #:nodoc:
      returning template.__send__(meth, *args, &block) do
        self.class.class_eval %{delegate :#{meth}, :to => :template}
      end
    end

    # DSL methods:

    def no_header
      @header_disabled = true
    end

    def field(field_name='', symbol = nil, &blk)
      fields << [field_name, symbol || blk]
    end

    #######
    private
    #######

    attr_reader :template

    def collection
      @collection ||= []
    end

    def fields
      @fields ||= []
    end

    def header?
      !@header_disabled
    end

    def value_for_field(value, item)
      case value
      when String
        value
      when Symbol
        if item.kind_of? Hash
          item[value]
        else
          item.send(value)
        end
      when Proc
        value.call(item)
      else
        value
      end
    end

  end

end
