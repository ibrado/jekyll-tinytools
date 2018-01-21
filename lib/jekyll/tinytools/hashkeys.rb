module Jekyll
  module TinyTools

    module HashKeys
      FACET = 'hashkeys'.freeze

      class LiquidObject
        def initialize(data)
          @liquid = {}

          if data.is_a?(::Hash)
            data.each do |k,v|
              if k =~ /^(keys|values|length)$/
                TinyTools.warn "Warning: conflict in data with method '#{k}'", FACET
              else
                @liquid[k] = v
              end
            end

            keys = @liquid.keys || []
            values = @liquid.values || []
            length = @liquid.length || 0

            @liquid['keys'] = keys
            @liquid['values'] = values
            @liquid['length'] = length

          else
            @liquid = data
          end
        end 

        def to_liquid
          @liquid
        end
      end

      class Tag < Liquid::Tag
        def initialize(tag_name, var, tokens)
          super

          var.strip!

          if m = /^(\S+)\s+(.+)$/.match(var)
            @var = m[1]
            @hash = JSON.parse(m[2].gsub("'",'"').gsub('=>',':')) || {}
          else
            @var = var
          end
        end

        def render(context)
          start_time = Time.now

          if @hash
            context.scopes.first[@var] = @hash
          end

          if @var
            scope = nil
            data = nil

            context.scopes.each do |s|
              if s[@var]
                scope = s
                data = scope[@var]
                break
              end
            end

            if data
              liquid = LiquidObject.new(data)
              scope[@var] = liquid
            end
          end

          elapsed = "%.3f" % (Time.now - start_time)
          TinyTools.verbose_tags nil, "Rendered in #{elapsed}s", FACET

          ''
        end
      end
    end

  end
end

Liquid::Template.register_tag(Jekyll::TinyTools::HashKeys::FACET,
  Jekyll::TinyTools::HashKeys::Tag)
