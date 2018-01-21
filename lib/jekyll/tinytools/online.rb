module Jekyll
  module TinyTools

    class Online < Liquid::Block
      FACET = 'online'.freeze
      TEST_URL = 'https://www.google.com/'.freeze
      TEST = 'test'.freeze
      ONLINE = 'Online'.freeze
      OFFLINE = 'Offline!'.freeze
      BLANK = ''.freeze

      def self.process(url)
        if TinyTools.online?.nil?
          if Utils.fetch(url || TEST_URL, FACET, false, true)
            TinyTools.online(true)
            TinyTools.debug TEST, ONLINE, FACET
          else
            TinyTools.online(false)
            TinyTools.debug TEST, OFFLINE, FACET
          end
        end
      end

      # Based 
      def initialize(tag_name, markup, tokens)
        super
        @blocks = []
        # We don't have markup?
        push_block(FACET, markup)
      end

      def parse(tokens)
        while parse_body(@blocks.last.attachment, tokens)
        end
      end

      def nodelist
        @blocks.map(&:attachment)
      end

      def unknown_tag(tag, markup, tokens)
        if tag == 'else'.freeze
          push_block(tag, markup)
        else
          super
        end
      end

     def push_block(tag, markup)
        block = if tag == 'else'.freeze
          Liquid::ElseCondition.new
        else
          parse_with_selected_parser(markup)
        end

        @blocks.push(block)
        block.attach(Liquid::BlockBody.new)
      end 

      def strict_parse(markup)
        if TinyTools.online?.nil?
          if Utils.fetch(TEST_URL, FACET, false)
            TinyTools.online(true)
          else
            TinyTools.debug 'http'.freeze, OFFLINE, FACET
            TinyTools.online(false)
          end
        end

        Liquid::Condition.new(TinyTools.online?)
      end

      alias lax_parse strict_parse

      def render(context)
        start_time = Time.now

        elapsed_time = lambda {
          elapsed = "%.3f" % (Time.now - start_time)
          TinyTools.verbose_all nil, "Rendered in #{elapsed}s", FACET
        }

        context.stack do
          @blocks.each do |block|
            if block.evaluate(context)
              elapsed_time.call()
              return block.attachment.render(context)
            end
          end
          elapsed_time.call()
          ''.freeze
        end
    
      end

    end

  end
end

Liquid::Template.register_tag(Jekyll::TinyTools::Online::FACET,
  Jekyll::TinyTools::Online)
