require 'open3'
require 'optparse'

require 'deathnote/version'
require 'debride'
require 'path_expander'

module Deathnote
  class << self
    def run(argv)
      options = parse_options(argv)
      backup_commit = System.cmd('git rev-parse --abbrev-ref HEAD')

      System.cmd("git checkout #{options[:past_commit]}")
      past_missing = DeadCodes.new(options.deep_clone).run

      System.cmd("git checkout #{options[:newer_commit]}")
      newer_missing = DeadCodes.new(options.deep_clone).run

      newer_missing.
        reject { |unused, _location| past_missing.has_key?(unused) }.
        each { |unused, location| puts "#{unused} #{location}" }
    ensure
      System.cmd("git checkout #{backup_commit}")
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
        opts.on('-n', '--newer-commit=[commit hash]', 'Specify newer commit hash.') do |newer_commit|
          options[:newer_commit] = newer_commit
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
    def initialize(options)
      @options = options
    end

    def run
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

  module System
    def self.cmd(command)
      Open3.popen3(command) { |_i, o, _e, _t| o.read.chomp }
    end
  end
end
