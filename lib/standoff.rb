require 'rexml/document'

module Standoff
  class AnnotatedString
    attr_accessor :signal, :tags; :afterda
    def initialize(options = {})
      if options[:signal] && options[:tags]
        @signal = options[:signal]
        @tags = options[:tags]
        @afterda = ['dispense', 'refill', 'sub_status']
      end
    end

    def tags (name = nil)
      # without an argument, this is just an attr_accessor
      return @tags unless name
      # with an argument return all tags of given name type
      @tags.select{|tag| tag.name == name}
    end
    
    def to_s
        #takes into consideration the ordering of tags
        xml = @signal.dup
        datags = []
        latetags = []
        oldbegin = xml.length
        
        @tags.sort.delete_if do |tag|
            if tag.name == 'doseamount'
                datags << tag
                false
            elsif @afterda.member? tag.name
                latetags << tag
                false
            elsif tag.end > oldbegin
                #stops tags from overlapping
                true
            else
                insert_tag(xml,tag)
                oldbegin = tag.start
                false
            end
        end
        
        datags.sort.each {|tag| insert_tag(xml,tag)}
        latetags.sort.each {|tag| insert_tag(xml,tag)}
        return xml
    end
    
    def insert_tag(text,tag)
        end_tag_form = '</' + tag.name + '>'
        text.insert(tag.end, end_tag_form)
        start_tag_form = '<' + tag.name + '>'
        text.insert(tag.start, start_tag_form)
        return text
    end
  end

  class XMLParser
    def initialize(source)
      @parser = REXML::Parsers::BaseParser.new(source)
      @signal = ""
      @tags = []
    end
    def parse
      while @parser.has_next?
        snip_type, snip = @parser.pull
        if snip_type == :text
          @signal += snip
        elsif snip_type == :start_element
          name, attributes = snip
          tag = Tag.new(:name => name, :attributes => attributes)
          snip_type, snip = @parser.pull
          raise ":text expected, #{snip_type.inspect}.found" if snip_type != :text
          tag.start = @signal.length
          tag.end = @signal.length + snip.length
          tag.content = snip
          @signal += snip
          snip_type, snip = @parser.pull
          raise ":end_element expected, #{snip_type.inspect}.found" if snip_type != :end_element
          raise "mismatched tag: \"#{snip}\" end_element following \"#{name}\" start_element" if snip != name
          @tags << tag
        end
      end
      return AnnotatedString.new(:signal => @signal, :tags => @tags)
    end
  end

  class Tag
    attr_accessor :name, :attributes, :content, :start, :end
    def initialize(options = {})
      @name = options[:name]
      @attributes = options[:attributes]
      @content = options[:content]
      @start = options[:start]
      @end = options[:end]
    end
    def <=> (other)
        #Returns reverse for AnnotatedString.to_s
        return other.end <=> @end
    end
  end
  
end

#p = Standoff::XMLParser.new("<freq>BID</freq> X up to <duration>3 weeks</duration>")
#s = p.parse
#puts p.inspect
#puts s.inspect
