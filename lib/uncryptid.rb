# frozen_string_literal: true

require 'rvg/rvg'

require 'uncryptid/board'
require 'uncryptid/clue'

module Uncryptid
  Point = Struct.new(:row, :col)

  TERRAINS = [
    :desert,
    :forest,
    :mountain,
    :swamp,
    :water,
  ]
  ANIMALS = [:bears, :cougars]
  BLUE_STRUCTURES  = [:blue_shack,  :blue_stone]
  GREEN_STRUCTURES = [:green_shack, :green_stone]
  WHITE_STRUCTURES = [:white_shack, :white_stone]
  BLACK_STRUCTURES = [:black_shack, :black_stone]
  ALL_STRUCTURES = BLUE_STRUCTURES + GREEN_STRUCTURES + WHITE_STRUCTURES + BLACK_STRUCTURES

  Mode = Struct.new(:name, :shacks, :stones, :include_black?, :include_not?)
  MODES = {
    normal: Mode.new(
      :normal,
      [:blue_shack, :green_shack, :white_shack],
      [:blue_stone, :green_stone, :white_stone],
      false, false
    ),
    advanced: Mode.new(
      :advanced,
      [:blue_shack, :green_shack, :white_shack, :black_shack],
      [:blue_stone, :green_stone, :white_stone, :black_stone],
      true, true
    ),
  }

  class Cell
    attr_reader :distances
    attr_accessor :type

    def initialize
      @distances = {}
      @distances.default = 4
    end
  end

  class << self
    def draw(board, filename)
      dy = Math.sqrt(3) / 2.0
      hexagon = lambda do |body, size|
        body.polygon(
          -1.0 * size,  0,
          -0.5 * size,  dy * size,
          0.5 * size,  dy * size,
          1.0 * size,  0,
          0.5 * size, -dy * size,
          -0.5 * size, -dy * size
        )
      end
      triangle = lambda do |body, color, size|
        body.g.rotate(90) do |t|
          t.styles(fill: color, stroke: "black", stroke_width: 1)
          t.polygon(
            -1.0 * size,  0,
            0.5 * size,  dy * size,
            0.5 * size, -dy * size
          )
        end
      end
      octogon = lambda do |body, color, size|
        r45 = Math.sqrt(2) / 2
        body.g.rotate(22.5) do |t|
          t.styles(fill: color, stroke: "black", stroke_width: 1)
          t.polygon(
            -1.0 * size,  0,
            -r45 * size,  r45 * size,
              0,           1.0 * size,
              r45 * size,  r45 * size,
              1.0 * size,  0,
              r45 * size, -r45 * size,
              0,          -1.0 * size,
            -r45 * size, -r45 * size
          )
        end
      end

      rvg = Magick::RVG.new(1000, 1000).viewbox(0, 0, 1000, 1000) do |canvas|
        canvas.background_fill = "white"
        terrain_colors = {
          forest: "LimeGreen",
          desert: "yellow2",
          mountain: "LightSteelBlue",
          water: "DeepSkyBlue2",
          swamp: "LightPink4",
        }
        animal_colors = {
          bears: "black",
          cougars: "red",
        }
        structure_property = {
          blue_shack: ["SteelBlue1", :triangle],
          blue_stone: ["SteelBlue1", :octogon],
          green_shack: ["chartreuse", :triangle],
          green_stone: ["chartreuse", :octogon],
          white_shack: ["white", :triangle],
          white_stone: ["white", :octogon],
          black_shack: ["black", :triangle],
          black_stone: ["black", :octogon],
        }
        canvas.translate(87, 131)
        size = 50

        Board::HEIGHT.times do |y|
          Board::WIDTH.times do |x|
            hex = board[Point.new(y, x)]
            next unless hex.type

            canvas.g.translate(size * x * 1.5, size * dy * (y * 2 + x % 2)) do |body|
              body.styles(fill: terrain_colors[hex.type], stroke: "white", stroke_width: 4)
              hexagon.call(body, size)
              ANIMALS.each do |a|
                next unless hex.distances[a] == 0
                body.g do |marker|
                  marker.styles(fill_opacity: 0, stroke: animal_colors[a], stroke_width: 3)
                  hexagon.call(marker, size * 0.8)
                end
              end
              ALL_STRUCTURES.each do |s|
                next unless hex.distances[s] == 0

                color, shape = structure_property[s]
                case shape
                when :triangle
                  triangle.call(body, color, size * 0.3)
                when :octogon
                  octogon.call(body, color, size * 0.3)
                end
              end
            end
          end
        end
      end
      rvg.draw.write(filename)
    end
  end
end
