module Jekyll
  module TinyTools

    class SoftWrap < Liquid::Block
      FACET = 'softwrap'.freeze

      def initialize(tag_name, params, tokens)
        super
        @params = params.strip!
      end

      def render(context)
        # Escape eol inside code blocks
        start_time = Time.now
        markup = super

        if @params == 'table'
          # Remove spaces and line ends from the lines
          # that don't start with a |
          markup.gsub!(%r[\s*#{$/}(?!\|)], '')

        else
          markup.scan(/(```|~~~+)(.*?)\1/m).each do |e|
            escaped = e[1].gsub(/#{$/}/, '~|$|')
            markup.gsub!(e[1], escaped)
          end

          # Also avoid lines ending with 2 spaces or backslashes
          # and those that are followed by lines indented by
          # tabs or at least 4 spaces

          markup.gsub!(%r[(?<!  |\\\\|#{$/})#{$/}(?!#{$/}|\t+|>| {4,})], ' ')
          markup.gsub!(%r(\\\\$), '')
          markup.gsub!('~|$|', $/)

          elapsed = "%.3f" % (Time.now - start_time)
          TinyTools.verbose_tags nil, "Rendered in #{elapsed}s", FACET
        end

        markup
      end
    end

  end
end

Liquid::Template.register_tag(Jekyll::TinyTools::SoftWrap::FACET,
  Jekyll::TinyTools::SoftWrap)
