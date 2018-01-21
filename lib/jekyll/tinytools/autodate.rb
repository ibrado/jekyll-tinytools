module Jekyll
  module TinyTools

    module AutoDate
      FACET = 'autodate'.freeze

      def self.process(item)
        start_time = Time.now

        type = (item.data[FACET] || item.data[TINYTOOLS] || 'mtime')
        if type =~ /now|rendere?d?|/
          source_file = Utils.source_file(item)
          date = File.mtime(source_file).to_s
        else
          date = Time.now.to_s
        end

        item.data['date'] = date

        elapsed = "%.3f" % (Time.now - start_time)
        TinyTools.verbose_tags item, "Processed in #{elapsed}s", FACET
      end
    end

  end
end
