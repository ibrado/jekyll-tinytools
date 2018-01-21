module Jekyll
  module TinyTools

    module CodeSpan
      FACET = 'codespan'.freeze

      def self.process(item)
        start_time = Time.now

        item.content.gsub!(/(?<!``)`[^\`\n]+`(?!``)/) { |code|
          "#{code}{:style='white-space: pre'}"
        }

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
      end

    end
  end
end
