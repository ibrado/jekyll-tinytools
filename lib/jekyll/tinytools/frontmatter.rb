module Jekyll
  module TinyTools

    module FrontMatter 
      FACET = 'frontmatter'.freeze
      YAML = '@yaml'.freeze
      DELETE = '@delete'.freeze

      def frontmatter(page, field = nil, value = nil, include_field = nil)
        start_time = Time.now

        response = ''
        if field.nil?
          response = page.to_yaml

        #elsif ['$dump'.freeze, '$yaml'.freeze].include?(value)
        elsif value == YAML
          obj = FrontMatter.get_field(page, field)
          if obj
            response = obj.to_yaml.chomp
            if include_field
              response.gsub!(/^---\n/,'')
              response.gsub!(/^/, '  ')
              response = "#{field}\n#{response}"
            end
          end

        elsif value == DELETE
          field.chomp!(':')
          FrontMatter.set_field(page, field, value)

        else
          field.strip!
          if field =~ /:$/
            field.chomp!(':')
            if value
              FrontMatter.set_field(page, field, value)
            else
              response = FrontMatter.get_field(page, field)
            end
          else
            FrontMatter.update_fields(page, /{{\s*#{field}\s*}}/, value)
          end
        end

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags nil, "Processed in #{elapsed}s", FACET

        response
      end

      def self.get_field(data, field)
        path = field.split(/[:\.]/)
        ref = data
        value = nil

        i = 1
        path.each do |f|
          if i == path.length
            m = /(.*?)\[(\d+)\]/.match(f)
            f = m[1] if m
            if m && !ref[f].nil? && ref[f].is_a?(Array)
              value = ref[f][m[2].to_i]
            else
              value = ref[f]
            end
            break
          else
            ref = ref[f]
            i += 1
          end
        end

        TinyTools.verbose_tags nil, "#{field}: #{value}", FACET
        value
      end

      def self.set_field(data, field, value)
        path = field.split(/[:\.]/)
        ref = data
        i = 0
        # Note: can change content
        path.each do |f|
          m = /(.*?)\[(\d+)\]/.match(f)
          array = m[1] if m
          if m && !ref[array].nil? && ref[array].is_a?(Array)
            f = m[2].to_i
            ref = ref[array]

            if value == DELETE
              ref.delete_at(f)
              return
            end
          end

          if i == path.length - 1
            if value == DELETE
              ref.delete(f)
              return
            end

            value.strip! if value.is_a?(String)
            ref[f] = value
            TinyTools.verbose_tags nil, "#{f} = '#{ref[f]}'", FACET
            break
          end

          ref = ref[f]

          i += 1
        end
      end

      def self.update_fields(data, pattern, value)
        data.each do |k, v|
          ref = v || k
          if ref.is_a?(Array) || ref.is_a?(Hash)
            self.update_fields(ref, pattern, value)
          elsif ref.is_a?(String) && (ref == v) && (ref =~ pattern) && (k != 'content') 
            ref.gsub!(pattern, value.to_s)
            TinyTools.verbose_tags nil, "#{k}: #{ref}", FACET
          end
        end
      end


    end

  end
end

Liquid::Template.register_filter(Jekyll::TinyTools::FrontMatter)
