#   Usage:
#       Tagalog::log(Whatever_I_Want_To_Log, tagging);
# 
#       Where:
#           Whatever_I_Want_To_Log    is something stringable, or an array of stringable things
#       And:
#           tagging    is either a tag symbol or an array of tag symbols
# 
# 
#   You can turn logging on or off for a given tag in the CONFIG AREA.


class Tagalog
  
  # THIS IS THE CONFIG AREA -- edit inline, or extend/override
  @@config = {
    # this path can be relative or absolute
    :log_file_path => "/var/log/tagalog.log",

    # set this to true if you want ALL logging turned off:
    :kill_switch => false,

    # set this to the desired time format string
    :date_format => "%Y-%m-%d @ %H:%M:%S",

    # set this to the desired message format, where
    #
    # $D = date
    # $T = tag
    # $M = message
    :message_format => "$D [ $T ] $M",

    # turn logging on and off here for various tags:
    :tags =>  {
      :tag_1 => true,
      :tag_2 => true,
      :tag_3 => true,
      :off => false,
      :force => true,

      # the default tag:
      :untagged => true, # this one is special
    }
  }
  
  @@writer = nil

  # @param message - mixed - something that can be cast as a string
  # @param tagging - mixed - a tag symbol or an array of tag symbols
  # @return boolean - whether or not logging occurred
  def self.log(message, tagging=:untagged)
    return false if @@config[:kill_switch]

    loggable_tags = self.get_loggable_tags tagging
    return false if loggable_tags.empty?
    
    message = self.format_message message
    return_me = false
    for tag in loggable_tags
      this_message = @@config[:message_format]
      this_message.gsub!(/\$(T|D|M)/) do |match|
        string = ''
        case match
        when '$D'
          string = Time.now.strftime(@@config[:date_format])
        when '$T'
          string = tagging
        when '$M'
          string = message
        end
        string
      end
      
      self.write_message this_message
      
      return_me = true
    end

    return_me
  end # /self.log

  def self.format_message message
    
    if message.is_a?(Hash) || message.is_a?(Array) || message.is_a?(Symbol)
      message
    elsif message.is_a?(String)
      message
    else
      raise TagalogException, "Message must be a hash, array, symbol, or string. You sent " + message.class.to_s
    end
  end # /self.format_message

  def self.write_message message
    if @@writer
      return @@writer.call(message)
    else
      path = @@config[:log_file_path]

      # turn absolute paths into relative ones
      if path[0,1] != '/'
        path = File.dirname(__FILE__) + '/' + path
      end
      
      open(path, 'a') { |f|
        f.puts message
      }
    end

  end # /self.write_message

  #
  # This takes a Method as its parameters, which it will call upon writing
  # rather than the standard write_method actions.  Good for distributed
  # platforms like Heroku
  #
  # Example:
  #
  # class TagalogWriters
  #    def self.heroku_writer(message)
  #      puts message
  #    end
  #  end
  # 
  # configure :production do
  #   Tagalog.set_writer(TagalogWriters.method(:heroku_writer))
  # end
  #
  def self.set_writer(closure)
    if closure.is_a? Method
      @@writer = closure 
    else
      raise TagalogException, "Writer must be a Methods"
    end
  end # /self.set_writer

  def self.config=(config)
    @@config = config
  end

  def self.config
    @@config
  end

  def self.get_loggable_tags(tagging)
    if tagging.is_a? Symbol
      tags = []
      tags = [tagging] unless @@config[:tags].has_key?(tagging) && !@@config[:tags][tagging]
    elsif tagging.is_a? Array
      # filter out any tags that are set to false in the config
      tags = tagging.select {|tag| !(@@config[:tags].has_key?(tag) && !@@config[:tags][tag] )}
    else
      raise TagalogException, "tagging must be a symbol or an array."
    end

    return tags
  end # /self.get_loggable_tags
end  # /class Tagalog

class TagalogException < Exception
  # pass
end


# <license stuff>
# 
# tagalog is licensed under The MIT License
# 
# Copyright (c) 2010 Kyle Wild (dorkitude) - available at http://github.com/dorkitude/tagalog
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# </license stuff>
