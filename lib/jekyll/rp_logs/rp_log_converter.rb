require_relative "rp_parser"
require_relative "rp_logline"
require_relative "rp_page"
require_relative "rp_arcs"
require_relative "rp_tags"

module Jekyll
  module RpLogs
    # Consider renaming since it is more of a converter in practice
    class RpLogGenerator < Jekyll::Generator
      safe true
      priority :normal

      @parsers = {}

      class << self
        attr_reader :parsers, :rp_key

        def add(parser)
          @parsers[parser::FORMAT_STR] = parser
        end

        ##
        # Extract global settings from the config file.
        # The rp directory and collection name is pulled out; it must be the
        # first collection defined.
        def extract_settings(config)
          @rp_key = config["collections"].keys[0].freeze
        end
      end

      def initialize(config)
        # Should actually probably complain if things are undefined or missing
        config["rp_convert"] = true unless config.key? "rp_convert"

        RpLogGenerator.extract_settings(config)
        LogLine.extract_settings(config)

        Jekyll.logger.info "Loaded jekyll-rp_logs #{RpLogs::VERSION}"
      end

      def generate(site)
        return unless site.config["rp_convert"]

        main_index, arc_index = extract_indexes(site)

        # Pull out all the pages that are error-free
        rp_pages = extract_valid_rps(site)

        convert_all_pages(site, main_index, arc_index, rp_pages)
      end

      private

      ##
      # Convenience method for accessing the collection key name
      def rp_key
        self.class.rp_key
      end

      ##
      #
      def extract_indexes(site)
        # Directory of RPs
        main_index = site.pages.find { |page| page.data["rp_index"] }
        main_index.data["rps"] = { "canon" => [], "noncanon" => [] }

        # Arc-style directory
        arc_index = site.pages.find { |page| page.data["rp_arcs"] }

        site.data["menu_pages"] = [main_index, arc_index]
      end

      ##
      # Returns a list of RpLogs::Page objects that are error-free.
      def extract_valid_rps(site)
        site.collections[rp_key].docs.map { |p| RpLogs::Page.new(p) }
          .reject do |p|
            message = p.errors?(self.class.parsers)
            skip_page(site, p, message) if message
            message
          end
      end

      def convert_all_pages(site, main_index, arc_index, rp_pages)
        arcs = Hash.new { |hash, key| hash[key] = Arc.new(key) }
        no_arc_rps = []

        # Convert all of the posts to be pretty
        # Also build up our hash of tags
        rp_pages.each do |page|
          begin
            # Skip if something goes wrong
            next unless convert_rp(site, page)

            key = page[:canon] ? "canon" : "noncanon"
            # Add key for canon/noncanon
            main_index.data["rps"][key] << page
            # Add tag for canon/noncanon
            page[:rp_tags] << (Tag.new key)
            page[:rp_tags].sort!

            arc_name = page[:arc_name]
            if arc_name && !arc_name.empty?
              arc_name.each { |n| arcs[n] << page }
            else
              no_arc_rps << page
            end

            Jekyll.logger.info "Converted #{page.basename}"
          rescue
            # Catch all for any other exception encountered when parsing a page
            skip_page(site, page, "Error parsing #{page.basename}: #{$ERROR_INFO.inspect}")
            # Raise exception, so Jekyll prints backtrace if run with --trace
            raise $ERROR_INFO
          end
        end

        arcs.each_key { |key| sort_chronologically! arcs[key].rps }
        combined_rps = no_arc_rps.map { |x| ["rp", x] } + arcs.values.map { |x| ["arc", x] }
        combined_rps.sort_by! { |type, x|
          case type
          when "rp"
            x[:time_line] || x[:start_date]
          when "arc"
            x.start_date
          end
        }.reverse!
        arc_index.data["rps"] = combined_rps

        sort_chronologically! main_index.data["rps"]["canon"]
        sort_chronologically! main_index.data["rps"]["noncanon"]
      end

      def sort_chronologically!(pages)
        # Check pages for invalid time_line value
        pages.each do |p|
          if p[:time_line] && !p[:time_line].is_a?(Date)
            Jekyll.logger.error "Malformed time_line #{p[:time_line]} in file #{p.path}"
            fail "Malformed time_line date, must be in the format YYYY-MM-DD"
          end
        end
        # Sort pages by time_line if present or start_date otherwise
        pages.sort_by! { |p| p[:time_line] || p[:start_date] }.reverse!
      end

      def convert_rp(site, page)
        options = page.options

        compiled_lines = []
        page.content.each_line { |raw_line|
          page[:format].each { |format|
            log_line = self.class.parsers[format].parse_line(raw_line, options)
            if log_line
              compiled_lines << log_line
              break
            end
          }
        }

        if compiled_lines.length == 0
          skip_page(site, page, "No lines were matched by any format.")
          return false
        end

        merge_lines! compiled_lines
        stats = extract_stats compiled_lines

        split_output = compiled_lines.map(&:output)
        page.content = split_output.join("\n")

        if page[:infer_char_tags]
          # Turn the nicks into characters
          nick_tags = stats[:nicks].map! { |n| Tag.new("char:" + n) }
          page[:rp_tags] = (nick_tags.merge page[:rp_tags]).to_a.sort
        end

        page[:end_date] = stats[:end_date]
        page[:start_date] ||= stats[:start_date]

        true
      end

      ##
      # Skip the page. Removes it from the site collection, and outputs a
      # warning message saying it was skipped with the given reason.
      def skip_page(site, page, message)
        site.collections[rp_key].docs.delete page.page
        Jekyll.logger.warn "Skipping #{page.basename}: #{message}"
      end

      ##
      # Consider moving this into Parser or RpLogs::Page
      # It doesn't really belong here
      def merge_lines!(compiled_lines)
        last_line = nil
        compiled_lines.reject! { |line|
          if last_line.nil?
            last_line = line
            false
          elsif last_line.mergeable_with? line
            last_line.merge! line
            # Delete the current line from output and maintain last_line
            # in case we need to merge multiple times.
            true
          else
            last_line = line
            false
          end
        }
      end

      def extract_stats(compiled_lines)
        nicks = Set.new
        compiled_lines.each { |line|
          nicks << line.sender if line.output_type == :rp
        }

        { nicks: nicks,
          end_date: compiled_lines[-1].timestamp,
          start_date: compiled_lines[0].timestamp }
      end
    end
  end
end
