module Jekyll
  module TinyTools

    module ProjectInfo
      FACET = 'project'.freeze

      GITHUB_API_PREFIX = "https://api.github.com/".freeze

      RUBYGEMS_API_PREFIX = "https://rubygems.org/api/v1/".freeze
      RUBYGEMS_API_SUFFIX = ".json".freeze

      @proj_info = {}

      def self.data(project, info = nil)
        info ? @proj_info[project] = info : @proj_info[project]
      end

      class Tag < Liquid::Tag
        def initialize(tag_name, text, tokens)
          super
          params = text.split(/\s+/)

          @project = params[0]  # ibrado/jekyll-tinytools
          @api = params[1]      # repos
          @field = params[2]    # pushed_at
          @var = params[3]      # my_var
        end

        def render(context)
          start_time = Time.now

          if @project =~ /\//
            @api ||= 'repos'
            @field ||= 'pushed_at'
            url ="#{GITHUB_API_PREFIX}#{@api}/#{@project}" 
          else
            @api ||= 'gems'
            @field ||= 'version'
            url ="#{RUBYGEMS_API_PREFIX}#{@api}/#{@project}#{RUBYGEMS_API_SUFFIX}" 
          end

          info = ProjectInfo.data(@project)

          if info.nil?
            #json = Utils.fetch(url, FACET, false)
            json = Utils.fetch(url, FACET)

            if json
              info = JSON.parse(json)
              ProjectInfo.data(@project, info)
            else
              info = {}
            end
          end

          field = Utils.get_field(info, @field) || '?'
          TinyTools.verbose_tags nil, "#{@project}/#{@api} #{@field}: #{field}", FACET

          if @var
            context.scopes.first[@var] = field
            response = ''
          else
            response = field
          end

          elapsed = "%.3f" % (Time.now - start_time)
          TinyTools.verbose_tags nil, "Rendered in #{elapsed}s", FACET

          response

        end
      end
    end

  end
end

Liquid::Template.register_tag(Jekyll::TinyTools::ProjectInfo::FACET,
  Jekyll::TinyTools::ProjectInfo::Tag)
