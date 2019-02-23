# frozen_string_literal: true

require 'rvg/rvg'

require 'uncryptid/board'
require 'uncryptid/clue'
require 'uncryptid/renderer'

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
end
