module Jekyll
  module TinyTools
    module RawCode
      FACET = 'rawcode'.freeze

      def self.process(item)
        start_time = Time.now

        content = item.content.dup
        #content = item.content

        #item.content.scan(/((?<!\\)(```|`)|(?<!\\)~{3,})(\s*.*?)(#{$/}*\1)/m) { |m|

        item.content.scan(/((?<!\\|`)(```|`|<code.*?>)|(?<!\\|~)~{3,})([^~`].*?)(#{$/}*(\1|<\/code.*?>))/m) { |m|
          block_content = m[2]
          next if block_content !~ /{[{%]/

          if f = /^(\s*\S+#{$/}+)(.+)/m.match(block_content)
            m[0] = m[0] + f[1]
            m[2] = f[2]
          end

          orig = "#{m[0]}#{m[2]}#{m[3]}"
          output = "#{m[0]}{% raw %}#{m[2]}{% endraw %}#{m[3]}"

          content.sub!(orig, output)
        }

        content.gsub!(/\\([`~])/, '\1')
        item.content = content

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
      end
    end
  end
end
