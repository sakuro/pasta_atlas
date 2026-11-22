# frozen_string_literal: true

require "fileutils"

module PastaAtlas
  # Replaces the sprites in a destination directory with those written by Factorio's
  # --dump-icon-sprites, which creates one directory of PNG files per prototype type.
  class FactorioIconImporter
    class NoSpritesError < StandardError; end

    Result = Data.define(:types, :sprites, :previous_sprites)

    def initialize(destination:)
      @destination = destination
    end

    def call(source)
      type_dirs = sprite_dirs(source)
      raise NoSpritesError, "No sprite directories found in #{source}" if type_dirs.empty?

      previous_sprites = sprites_in(@destination)
      replace_destination(type_dirs)
      Result[types: type_dirs.size, sprites: sprites_in(@destination), previous_sprites:]
    end

    # The script output directory also holds other things, such as mapshot's output, whose
    # directories do not contain PNG files directly.
    private def sprite_dirs(source)
      dirs = source.children.select {|child| child.directory? && png_files(child).any? }
      dirs.sort!
    end

    private def png_files(dir) = dir.children.select {|child| child.file? && child.extname == ".png" }

    private def sprites_in(dir)
      return 0 unless dir.directory?

      dir.children.select(&:directory?).sum {|type_dir| png_files(type_dir).size }
    end

    # The new tree is built beside the destination and swapped in, so a failure while copying
    # leaves the current sprites untouched.
    private def replace_destination(type_dirs)
      staging = @destination.parent.join(".#{@destination.basename}.staging")
      FileUtils.rm_rf(staging)
      begin
        type_dirs.each {|type_dir| copy_type(type_dir, staging.join(type_dir.basename)) }
        FileUtils.rm_rf(@destination)
        staging.rename(@destination)
      ensure
        FileUtils.rm_rf(staging)
      end
    end

    # Written with binwrite rather than FileUtils.cp, which would carry over the permissions of
    # the source; a dump made on a Windows drive is executable, and git would record that.
    private def copy_type(type_dir, target)
      FileUtils.mkdir_p(target)
      png_files(type_dir).each {|file| File.binwrite(target.join(file.basename), file.binread) }
    end
  end
end
