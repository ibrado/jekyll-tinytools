module Jekyll
  module TinyTools
    module ImportMd
      FACET = 'importmd'.freeze
      CACHE_EXPIRY = 600 # seconds

      def self.process(item)
        start_time = Time.now

        content = item.content.dup

        # Pre-scan for this as tags are processed last
        # but other plugins may want to process the imported markdown

        item.content.scan(/(\s*{%\s*#{FACET}\s+(["']?)(\S+)\2\s*(.*?)\s*%}#{$/}*)/) do |params|
          all = Regexp.escape(params[0])

          url = URI.encode(params[2])
          opts = params[3].split(/\s+/)

          if remote_md = Utils.fetch(url, FACET)
            content.gsub!(/#{all}/, $/ + remote_md)

            if opts.any? { |v| v =~ /remove_?toc/ }
              content.sub!(/((^|\s+)[+\*\-]\s*\[.*?\]\(.*?\)){1,}/, '')
            end

            #source_file = Utils.source_file(item)
            #Utils.update_timestamp_once(source_file)

          else
            content.gsub!(/#{all}/, "Error retrieving #{url}")
          end
        end

        item.content = content

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
      end

      class Tag < Liquid::Tag
        def initialize(tag_name, text, tokens)
          super
          params = text.split(/\s+/)

        end

        def render(context)
          ''
        end
      end

    end
  end
end


Liquid::Template.register_tag(Jekyll::TinyTools::ImportMd::FACET, Jekyll::TinyTools::ImportMd::Tag)
