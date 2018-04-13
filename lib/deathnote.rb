require 'open3'
require 'optparse'

require 'deathnote/version'
require 'debride'
require 'path_expander'

module Deathnote
  class << self
    def run(argv)
      options = parse_options(argv)
      old_commit = Open3.popen3('git rev-parse --abbrev-ref HEAD') { |_i, o, _e, _t| o.read.chomp }

      base_missing = DeadCodes.new(commit: options[:past_commit], options: options.deep_clone).run
      pr_missing = DeadCodes.new(commit: options[:compare_commit], options: options.deep_clone).run
      Open3.popen3("git checkout #{old_commit}")

      pr_missing.
        reject { |unused, _location| base_missing.has_key?(unused) }.
        each { |unused, location| puts "#{unused} #{location}" }
    end

    private

    def parse_options(argv)
      options = {}
      OptionParser.new do |opts|
        opts.banner = 'Usage: deathnote [options] files_or_dirs'

        opts.on('-h', '--help', 'Display this help.') do
          puts opts
          exit
        end
        opts.on('-p', '--past-commit=[commit hash]', 'Specify past commit hash.') do |past_commit|
          p past_commit
          options[:past_commit] = past_commit
        end
        opts.on('-c', '--compare[commit hash]', 'Specify compare commit hash.') do |compare_commit|
          options[:compare_commit] = compare_commit
        end
        opts.on('-r', '--rails', 'Filter some rails call conversions.') do
          options[:rails] = true
        end
        opts.on('-e', '--exclude=file1,file2,etc', Array, 'Exclude files or directories in comma-separated list.') do |list|
          options[:exclude] = list
        end
      end.parse!
      options[:target_paths] = argv

      options
    rescue OptionParser::InvalidOption => e
      warn "Fail to parse options."
      warn e.message
      exit 1
    end
  end

  class DeadCodes
    def initialize(commit:, options:)
      @commit = commit
      @options = options
    end

    def run
      Open3.popen3("git checkout #{@commit}")
      to_list(run_debride)
    end

    private

    def run_debride
      debride = Debride.new(@options)

      extensions = Debride.file_extensions
      glob = "**/*.{#{extensions.join(",")}}"
      expander = PathExpander.new(@options[:target_paths], glob)
      files = expander.process
      excl  = debride.option[:exclude]
      files = expander.filter_files files, StringIO.new(excl.join "\n") if excl

      debride.run(files)
      debride
    end

    def to_list(debride)
      unuseds = {}
      method_locations = debride.method_locations

      debride.missing.each do |klass, meths|
        meths.each do |meth|
          type = method_locations["#{klass}##{meth}"].nil? ? '::' : '#'
          location = method_locations["#{klass}#{type}#{meth}"]
          path = location[/(.+):\d+$/, 1]

          unuseds["#{klass}#{type}#{meth}"] = location
        end
      end

      unuseds
    end
  end
end
