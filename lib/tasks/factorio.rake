# frozen_string_literal: true

require "open3"
require_relative "../pasta_atlas/factorio_icon_importer"

namespace :factorio do
  desc "Replace frontend/factorio-icons with the output of `factorio --dump-icon-sprites`. " \
       "Pass the dump directory as an argument; it defaults to the script output directory reported by factorix."
  task :import_icons, [:source] do |_task, args|
    source =
      if args[:source]
        Pathname(args[:source])
      else
        output, status = Open3.capture2("factorix", "path")
        abort "factorix path failed" unless status.success?

        line = output.lines.find {|l| l.start_with?("script_output_dir") }
        abort "script_output_dir is not reported by factorix path" unless line

        Pathname(line.split(nil, 2).last.strip)
      end
    abort "Not a directory: #{source}" unless source.directory?

    destination = Pathname(__dir__).join("../../frontend/factorio-icons").expand_path

    begin
      result = PastaAtlas::FactorioIconImporter.new(destination:).call(source)
    rescue PastaAtlas::FactorioIconImporter::NoSpritesError => e
      abort e.message
    end

    puts "Imported #{result.sprites} sprites in #{result.types} types from #{source} " \
         "(previously #{result.previous_sprites} sprites)"
    puts "Next: mise run icons:css"
  end
end
