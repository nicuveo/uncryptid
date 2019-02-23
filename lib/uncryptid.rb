# frozen_string_literal: true

require 'rvg/rvg'

require 'uncryptid/board'
require 'uncryptid/clue'
require 'uncryptid/renderer'

module Uncryptid
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

  class Location
    attr_reader :col, :row

    def initialize(col:, row:)
      @col = col
      @row = row
    end

    def inspect
      "#<Location #{self}>"
    end

    def to_s
      "(#{col}, #{row})"
    end

    def neighbours
      directions = [
        Location.new(row: -1, col:  0),
        Location.new(row:  1, col:  0),
        Location.new(row:  0, col: -1),
        Location.new(row:  0, col:  1),
      ]
      directions += if col.even?
        [
          Location.new(row: -1, col: -1),
          Location.new(row: -1, col:  1),
        ]
      else
        [
          Location.new(row: 1, col: -1),
          Location.new(row: 1, col:  1),
        ]
      end

      directions.map { |dir| self + dir }
    end

    def +(other)
      Location.new(
        col: col + other.col,
        row: row + other.row,
      )
    end
  end

  class Cell
    attr_reader :distances
    attr_accessor :type

    def initialize
      @distances = {}
      @distances.default = 4
    end
  end
end
