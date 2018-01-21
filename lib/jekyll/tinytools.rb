require 'uri'
require 'digest'
#require 'htmlbeautifier'
#require 'rouge'

#require_relative 'lib/utils'
#require_relative 'lib/cache'

module Jekyll
  module TinyTools
    TINYTOOLS = 'tinytools'.freeze
    TINYTOOLS_LOG = 'TinyTools:'.freeze

    # We have to run this after the site is written 
    # so we can read HTML output
    Jekyll::Hooks.register :site, :post_write do |site|
      ViewSource.render_source_files
    end

    def self.debug_state(debug)
      @debug ||= debug
    end

    def self.site(site = nil)
      @site ||= site
    end

    def self.warn(msg, facet = nil)
      msg = "[#{facet}] #{msg}" if facet 
      Jekyll.logger.warn TINYTOOLS_LOG, msg
    end

    def self.verbose(item, msg, facet = nil)
      debug(item, msg, facet) if @debug.to_s =~ /(verbose|tags|all)/
    end

    def self.verbose_tags(item, msg, facet = nil)
      debug(item, msg, facet) if @debug.to_s =~ /(tags|all)/
    end

    def self.verbose_all(item, msg, facet = nil)
      debug(item, msg, facet) if @debug.to_s == 'all'
    end

    def self.debug(item, msg, facet = nil)
      if @debug
        info = (item.respond_to?(:path) ? File.basename(item.path) : item) || 'liquid'
        if facet
          msg = "[#{facet}] [#{info}] #{msg}"
        else
          msg = "[#{info}] #{msg}"
        end

        Jekyll.logger.warn TINYTOOLS_LOG, msg
      end
    end

    def self.online?
      @is_online
    end

    def self.online(state)
      @is_online = state
    end


    ##### Main generator ###############################################

    class Generator < Jekyll::Generator
      # Run at highest priority since we may actually change source content
      priority :highest

      def generate(site)
        @start_time = Time.now
        @site = site
        TinyTools.site site

        config = site.config[TINYTOOLS] || {}

        # XXX
        TinyTools.debug_state(config['debug'] || true)
        #TinyTools.debug_state(config['debug'] || 'tags')

        Cache.setup(site, config['cache'].nil? || config['cache'])

        # Check if online now so this is only done once
        Online.process(config['online_test_url'])

        collections = [ config['collection'], config["collections"] ].flatten.compact;
        collections = ['pages', 'posts'] if collections.empty?

        collections.each do |collection|
          if collection == "pages"
            items = site.pages
          else
            next if !site.collections.has_key?(collection)
            items = site.collections[collection].docs
          end

          selection = items.select { |item| item.data[TINYTOOLS] }

          selection.each do |item|
            item_start = Time.now
            TinyTools.verbose '<' + File.basename(item.path), "Starting"
            tools = item.data[TINYTOOLS] || ''

            # The order is semi-important so they can work together
            #ViewSource.process(item) if tools =~ /#{ViewSource::FACET}/
            #if tools =~ /#{Constants::FACET}/
            #  const_macro = %q({% macro '^{%\s*const(ant|)\s+) +
            #    %q(([A-Z_]+)(\s*=?)\s*(["']?)(.*?)\4\s*%}\r?\n' ) +
            #    %q('{% macro "[=$]\2" "\5" %}' %}) + "\n"
            #
            #  item.content = const_macro + item.content
            #end

            AutoDate.process(item) if tools =~ /#{AutoDate::FACET}/
            RawCode.process(item) if tools =~ /#{RawCode::FACET}/
            Macros.process(item) if tools =~ /#{Macros::FACET}/
            Constants.process(item) if tools =~ /#{Constants::FACET}/
            Comments.process(item) if tools =~ /#{Comments::FACET}/

            ImportMd.process(item) if tools =~ /#{ImportMd::FACET}/

            CodeSpan.process(item) if tools =~ /#{CodeSpan::FACET}/

            #AutoToc.process(item) if tools =~ /#{AutoToc::FACET}/

            # project is a tag
            # hashkeys is a tag

            # softwrap is a block tag, {% softwrap %} .. {% endsoftwrap %}
            # frontmatter is a filter
            
            elapsed = "%.3f" % (Time.now - item_start)
            TinyTools.verbose File.basename(item.path)+'>', "Elapsed time: #{elapsed}s"
          end
        end

        #TinyTools.online(nil) # Try again next regen

        elapsed = "%.3f" % (Time.now - @start_time)
        TinyTools.debug 'main loop', "Elapsed time: #{elapsed}s"
      end
    end

  end
end

