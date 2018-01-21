require 'net/http'

module Jekyll
  module TinyTools

    #CODE_BLOCK_ESCAPE_RE = %r[
    #  (^```|^~~~+)(.*?)\1   # Standard and fenced code blocks
    #  | (?<!`)`(.*?)`(?!`)          # Code spans
    #  | <!--(.*?)-->        # HTML comments
    #  | {%\s*capture.*?%}(.*?){%\s*endcapture\s*%}  # Liquid capture
    #]mx


    CODE_BLOCK_ESCAPE_RE = %r[
      ((^```).*?\2)   # Standard and fenced code blocks
      | ((^~~~+).*?\4)   # Standard and fenced code blocks
     | (?<!`)(`.*?`)(?!`)          # Code spans
     | (<!--.*-->)        # HTML comments
     | ({%\s*capture.*?%}.*?{%\s*endcapture\s*%})  # Liquid capture
    ]mx

    CODE_LINE_ESCAPE_RE = %r[ # Indented blocks
      ^                 # Must start with
      (?=>|\t+|\ {4,})  # ...  >, tabs, or 4+ spaces
      (.*?)         # <-- capture it for escaping; empty () for union
      $
    ]x

    CODE_ESCAPE_RE = Regexp.union(CODE_BLOCK_ESCAPE_RE, CODE_LINE_ESCAPE_RE)

    module Utils
      @touched = {}
      @cache = {}

      CACHE_EXPIRY = 600 # seconds

      def self.update_timestamp_once(source_md)
        if source_md
          unless @touched[source_md]
            FileUtils.touch source_md
            @touched[source_md] = 1
          end
        end
      end

      def self.fetch(url, facet = nil, use_cache = true, force = false)
        facet ||= 'default'

        if use_cache && (force || Cache.valid?(url, 'response', CACHE_EXPIRY))
          if_avail = force ? ' if available' : ''
          TinyTools.debug 'cache', "Using cached #{url}#{if_avail}", facet
          Cache.contents(url, 'response')

        elsif m = %r[^file://(.+)].match(url)
          local_file = m[1]
          if File.exist? local_file
            content = File.read(local_file)
          else
            TinyTools.warn "Unable to read #{url}", facet
            content = nil
          end

        elsif use_cache && !TinyTools.online?.nil? && !TinyTools.online?
          TinyTools.debug 'http', "Site is offline, trying cache", facet
          content = Utils.fetch(url, facet, true, true)

        else
          TinyTools.debug 'http', "Fetching #{url}", facet

          begin
            # TODO: Add error handling
            content = Net::HTTP.get(URI(url)).force_encoding(Encoding.default_external)
            #response = Net::HTTP.get_response(URI(url)).force_encoding(Encoding.default_external)

            #case response
            #when Net::HTTPSuccess then
            #  content = response
            #else
            #  p response.value
            #end

            if use_cache
              # Save new contents
              Cache.contents(url, 'response', content)
            end
         rescue
            TinyTools.warn "Unable to retrieve #{url}", facet
            if force
              content = nil
            else
              content = Utils.fetch(url, facet, true, true)
            end
          end

          content
        end
      end

      def self.uncache(url = 'all', facet = nil)
        set = facet || 'default'
        @cache[set] ||= {}

        TinyTools.debug 'cache', "Removing #{url} from cache", facet if facet && !@cache[set].empty?
        if url == 'all'
          @cache.delete(set)
        else
          @cache[set].delete(url)
        end

      end

      def self.get_field(data, field)
        #field.split(/[:\.]/).inject(data) { |k, v| k[v] }
        path = field.split(/[:\.]/)
        ref = data
        path.each do |f|
          if m = /^(.*?)\[(\d+)\]/.match(f)
            f = m[1]
            i = m[2].to_i
          else
            i = nil
          end
          if i && ref[f].is_a?(Array)
            ref = ref[f][i]
          else
            ref = ref[f]
          end
        end
        ref
      end

      def self.source_file(item)
        source_prefix = item.is_a?(Jekyll::Page) ? TinyTools.site.source : ''
        File.join(source_prefix, item.path)
      end

      def self.modified?(source, dest, expiry = nil)
        dest && !dest.empty? && 
          (!File.exist?(dest) || 
            (source && (File.mtime(source) > File.mtime(dest))) ||
            (expiry && ((File.mtime(dest) + expiry) <= Time.now ))
          )
      end

      def self.codeblocks(content, re = CODE_ESCAPE_RE, shift_items = 1)
        blocks = []

        content.scan(re).each do |e|
          #e.shift(shift_items)

          #block_contents = e.compact.first
          block_contents =  (e[0] || e[2] || e[4] || e[5] || e[6] || e[7])

          if block_contents && !block_contents.empty?
            blocks << block_contents
          end
        end

        blocks
      end

    end
  end
end

