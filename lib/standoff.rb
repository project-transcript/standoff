=begin
Copyright 2015 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'rexml/document'

module Standoff
  class AnnotatedString
    attr_accessor :signal, :tags
    def initialize(options = {})
      if options[:signal] && options[:tags]
        @signal = options[:signal]
        @tags = options[:tags]
      end
    end

    def tags (name = nil)
      # without an argument, this is just an attr_accessor
      return @tags unless name
      # with an argument return all tags of given name type
      @tags.select{|tag| tag.name == name}
    end
    
    def to_s # return the signal as a string with tags interpolated as inline XML
      #takes into consideration the ordering of tags
      xml = @signal.dup
      datags = []
      latetags = []
      oldbegin = xml.length
      
      # insert tags starting from the end of the string, so we can rely on the start and end indices
      @tags.sort.reverse.each do |tag|
        next if tag.end > oldbegin # AS allows overlapping tags, but we have to filter them when serializing to inline
        oldbegin = tag.start
        insert_tag(xml,tag)
      end
      
      xml
    end

    def inspect # re-define, otherwise the to_s overrides the default inspect
      vars = self.instance_variables. 
        map{|v| "#{v}=#{instance_variable_get(v).inspect}"}.join(", ") 
      "<#{self.class}: #{vars}>" 
    end
    
    
    def insert_tag(text,tag)
        end_tag_form = '</' + tag.name + '>'
        text.insert(tag.end, end_tag_form)
        start_tag_form = '<' + tag.name + tag.attributes.map{|k, v| " #{k}=\'#{v}\'"}.join + '>'
        text.insert(tag.start, start_tag_form)
        return text
    end

    def previous_tag (tag)
      # it's too bad we have to sort these every time. we should make @tags always be sorted.
      tags = @tags.sort
      index = tags.index tag
      # we assume tag is a tag on self
      raise "error in Standoff::AnnotatedString#previous_tag: argument should be a member of self.tags" if index.nil?
      index > 0 ? tags[index - 1] : nil
    end

    def next_tag (tag)
      # it's too bad we have to sort these every time. we should make @tags always be sorted.
      tags = @tags.sort
      index = tags.index tag
      # we assume tag is a tag on self
      raise "error in Standoff::AnnotatedString#previous_tag: argument should be a member of self.tags" if index.nil?
      index < tags.length-1 ? tags[index + 1] : nil
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
      @name = options[:name] # string
      @attributes = options[:attributes] # hash
      @content = options[:content] # string
      @start = options[:start] # numeric
      @end = options[:end] 
    end
    def <=> (other)
        return @end <=> other.end
    end
    def overlap (other_tag)
      ! ((@start .. @end).to_a & (other_tag.start .. other_tag.end).to_a).empty?
    end
  end
  
end

