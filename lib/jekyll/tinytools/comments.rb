module Jekyll
  module TinyTools

    class Comments
      FACET = 'comments'.freeze

      def self.process(item, transform_comments = nil)
        start_time = Time.now

        content = item.content.dup

        # Escape comments inside code blocks
        escapees = { '//' => '~|$$|', '/*' => '~|$*|', '*/' => '~|*$|' }
        esc_re = Regexp.union(escapees.keys)

        detainees = escapees.invert
        unesc_re = Regexp.union(detainees.keys)

        scan_content = content.dup
        Utils.codeblocks(scan_content).each do |block_contents|
          escaped = block_contents.dup
          escapees.each { |k,v| escaped.gsub!(k,v) }

          content.sub!(block_contents, escaped)
        end

        if transform_comments
          content.gsub!(%r(/[*](.*?)([*]/|~\|\*\$\|))m) {
            comment = $1.strip
            lines = ''
            comment.split("#{$/}").each { |line|
              lines += $/ if !lines.empty?
              line.sub!(/^\s+/, '')
              lines += "[//]: # (#{line})"
            }
            $/ + lines
          } 

          content.gsub!(%r{^(.*?)(?<![:\[])//\s*(.*?)(\s*)$}) {
            prefix = $1
            prefix += $/ if !prefix.empty?
            "#{prefix}[//]: # (#{$2})#{$3}"
          }

        else
          content.gsub!(%r(\s*/[*].*?([*]/|~\|\*\$\|))m, '') 
          content.gsub!(%r{\s*(?<![:\[])//.*?$}, "\n")
        end

        # Reverse the escape
        content.gsub!(unesc_re, detainees)

        item.content = content

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
      end
    end

  end
end
