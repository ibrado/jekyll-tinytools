require 'strscan'

module Jekyll
  module TinyTools

    class Constants
      TAG = 'constant'.freeze
      FACET = "#{TAG}s".freeze

      def self.process(item)
        start_time = Time.now
        content = item.content.dup

        constants = {}
        content.scan(/{%\s*#{TAG}\s+([A-Z_][A-Z_0-9]+)(\s*=?)\s*(["']?)(.*?)\3\s*%}/) do |params|
          const = params[0].strip
          value = params[3]

          #lm = Regexp.last_match
          #puts "SAW #{const}=#{value} AT #{lm.offset(1)}"

          value.gsub!(/[=\$]([A-Z_][A-Z_0-9]+)\b/) {
            #c = Regexp.last_match[1]
            constants[$1]
          }
          constants[const] = value
        end

        content.gsub!(/[=\$]([A-Z_][A-Z_0-9]+)\b/) {
          #c = Regexp.last_match[1]
          constants[$1]
        }

        item.content = content

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
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

Liquid::Template.register_tag(Jekyll::TinyTools::Constants::TAG,
  Jekyll::TinyTools::Constants::Tag)

