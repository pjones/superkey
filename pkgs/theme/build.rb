#!/usr/bin/env ruby

################################################################################
require('json')

################################################################################
class Build

  ##############################################################################
  def initialize(colors_file, dir)
    @colors = JSON.parse(File.read(colors_file))
    @dir = dir
  end

  ##############################################################################
  def run
    gen_css
    gen_sway
  end

  ##############################################################################
  private

  ##############################################################################
  def gen_css
    File.open(File.join(@dir, "colors.css"), "w") do |file|
      @colors.each do |name, hex|
        file.puts("@define-color #{name} #{hex};")
      end
    end
  end

  ##############################################################################
  def gen_sway
    colors = {
      # class                    border     bground   text      indicator child_border
      "client.focused":          ["base0D", "base0D", "base00", "base0F", "base0D"],
      "client.focused_inactive": ["base01", "base01", "base05", "base03", "base01"],
      "client.unfocused":        ["base01", "base00", "base05", "base03", "base01"],
      "client.urgent":           ["base08", "base08", "base00", "base08", "base08"],
    }

    File.open(File.join(@dir, "sway.cfg"), "w") do |file|
      colors.each do |klass, names|
        hex = names.map {|name| @colors.fetch(name)}.join(" ")
        file.puts("#{klass} #{hex}")
      end
    end
  end
end

Build.new(*ARGV).run
