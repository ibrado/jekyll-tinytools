module Jekyll
  module TinyTools

    class Macros
      TAG = 'macro'.freeze
      FACET = "#{TAG}s".freeze

      def self.process(item)
        start_time = Time.now
        content = item.content.dup

        #i=1
        #while content =~ /^({%\s*#{TAG}\s)/
        #  puts "PROCESSING #{i}"
          content = process_macros(content)
        #  i += 1
        #end

        item.content = content

        @macros = {}

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
      end

      def self.macros
        @macros ||= {}
      end

      def self.process_macros(content)
        definitions = [] 
        reprocess = false

        # Aliases for editor/viewsource syntax highlight
        aliases = { 
          ':star:' => '*',
          ':aster:' => '*',
          ':asterisk:' => '*',
          ':percent:' => '%',
          ':underscore:' => '_',
          ':underline:' => '_',
          ':under:' => '_',
          ':lt:' => '<',
          ':gt:' => '>',
          ':amp:' => '&',
          ':lob:' => '{{',
          ':lcb:' => '}}',
          ':lop:' => '{%',
          ':lcp:' => '%}'
        }

        content.scan(/(^{%\s*#{TAG}\s+(["'\/]?)(.*?)\2\/?(\S*)\s+(["'\{])(.*?)(\5|\})\s*%}#{$/}?)/m) do |params|

          definitions << Regexp.new('^'+Regexp.escape(params[0]))

          regex = params[2]
          options = params[3]
          replacement = params[5]
          
          if replacement =~ /#{$/}/
            replacement.gsub!(/^\s+{%/, '{%')
            reprocess = true
          end

          #puts
          #puts "REGEX #{regex.inspect} OPTIONS: #{options} => #{replacement.inspect}"
          #puts
          opts = 0
          opts |= Regexp::MULTILINE if options =~ /m/
          opts |= Regexp::IGNORECASE if options =~ /i/
          opts |= Regexp::EXTENDED if options =~ /x/

          macros.each do |regex_prev, repl_prev|
            #puts "PREV -> #{regex_prev.inspect}"
            regex.gsub!(regex_prev, repl_prev)
            replacement.gsub!(regex_prev, repl_prev)
          end

          aliases.each { |k,v| 
            regex.gsub!(k,v) 
            replacement.gsub!(k,v) 
          }

          #regex.gsub!(/\$(\d+)/) { '\\\\' + $1 }
          replacement.gsub!(/\$(\d+)/) { '\\\\' + $1 }

          regex.gsub!(/:(\d+):/) { $1.to_i.chr }
          replacement.gsub!(/:(\d+):/) { $1.to_i.chr }

          regex.gsub!(/\\([rn])/) { $1 == "r" ? "\r" : "\n" }
          replacement.gsub!(/\\([rn])/) { $1 == "r" ? "\r" : "\n" }

          if regex && replacement
            #puts "REPLACING #{regex.inspect} WITH #{replacement.inspect}"
            re = Regexp.new(regex, opts)
            macros[re] = replacement
          end
        end

        re_union = Regexp.union(definitions)
        content.gsub!(re_union, '')

        macros.each do |regex, replacement|
          #puts "REPLACING #{regex.inspect} => #{replacement}"
          reprocess ||= content.gsub!(regex, replacement)
        end

        if reprocess
          return process_macros(content)
        else
          content
        end
      end

      class Tag < Liquid::Tag
        def initialize(tag_name, var, tokens)
          super
        end

        def render(context)
          ''
        end
      end
    end

  end
end

Liquid::Template.register_tag(Jekyll::TinyTools::Macros::TAG,
  Jekyll::TinyTools::Macros::Tag)

