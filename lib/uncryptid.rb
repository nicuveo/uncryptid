# frozen_string_literal: true

require 'rvg/rvg'

module Uncryptid
  ### Point

  Point = Struct.new(:row, :col)



  ### Elements

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
  ALL_STRUCTURES = BLUE_STRUCTURES  + GREEN_STRUCTURES + WHITE_STRUCTURES + BLACK_STRUCTURES



  ### Modes

  Mode = Struct.new(:name, :shacks, :stones, :include_black?, :include_not?)

  NORMAL = Mode.new(
    :normal,
    [:blue_shack, :green_shack, :white_shack],
    [:blue_stone, :green_stone, :white_stone],
    false, false
  )
  ADVANCED = Mode.new(
    :advanced,
    [:blue_shack, :green_shack, :white_shack, :black_shack],
    [:blue_stone, :green_stone, :white_stone, :black_stone],
    true, true
  )



  ### Cell

  class Cell
    attr_reader :distances
    attr_accessor :type

    def initialize
      @distances = {}
      @distances.default = 4
    end
  end



  ### Board

  class Board
    WIDTH = 12
    HEIGHT = 9

    class << self
      def [](t1,t2,t3,t4,t5,t6,elements={})
        res = Board.new
        add_tile(res, t1, 0, 0)
        add_tile(res, t2, 0, 6)
        add_tile(res, t3, 3, 0)
        add_tile(res, t4, 3, 6)
        add_tile(res, t5, 6, 0)
        add_tile(res, t6, 6, 6)
        elements.each { |pos, elem| res.add(pos, elem) }

        res
      end

      def is_in?(pos)
        pos.col >= 0 && pos.col < WIDTH &&
          pos.row >= 0 && pos.row < HEIGHT
      end

      def neighbours(pos)
        r = pos.row
        c = pos.col
        result = if c.even?
          [
            Point.new(r-1,c  ),
            Point.new(r+1,c  ),
            Point.new(r,  c-1),
            Point.new(r,  c+1),
            Point.new(r-1,c-1),
            Point.new(r-1,c+1),
          ]
        else
          [
            Point.new(r-1,c  ),
            Point.new(r+1,c  ),
            Point.new(r,  c-1),
            Point.new(r,  c+1),
            Point.new(r+1,c-1),
            Point.new(r+1,c+1),
          ]
        end

        result.select { |p| is_in?(p) }
      end

      private

      def add_tile(board, tileinfo, row, col)
        ti = tileinfo.dup
        name = ti.shift
        case ti
        when []
          TILES[name].each_with_index do |line, dy|
            line.each_with_index do |cell, dx|
              elements = cell.dup
              type = elements.shift
              board.set(Point.new(row + dy, col + dx), type, elements)
            end
          end
        when [:upside_down]
          TILES[name].each_with_index do |line, dy|
            line.each_with_index do |cell, dx|
              elements = cell.dup
              type = elements.shift
              board.set(Point.new(row + 2 - dy, col + 5 - dx), type, elements)
            end
          end
        else
          puts "ERROR"
          # TODO: crash the program
        end
      end
    end

    def initialize
      @data = Array.new(WIDTH * HEIGHT) { Cell.new }
    end

    def [](pos)
      @data[pos.row * WIDTH + pos.col] if Board.is_in?(pos)
    end

    def set(pos, type, elements)
      self[pos].type = type
      propagate(pos, type)
      elements.each { |e| propagate(pos, e) }
    end

    def add(pos, element)
      propagate(pos, element)
    end

    def distance(pos, element)
      self[pos]&.distances[element]
    end

    private

    def propagate(pos, element)
      queue = [[pos, 0]]
      while (current, d = queue.shift)
        ds = self[current].distances
        if d < ds[element]
          ds[element] = d
          queue += Board.neighbours(current).map{|p| [p,d+1]}
        end
      end
    end
  end



  ### Tiles
  TILES = {
    tile1: [
      [[:water], [:water], [:water], [:water], [:forest], [:forest]],
      [[:swamp], [:swamp], [:water], [:desert], [:forest], [:forest]],
      [[:swamp], [:swamp], [:desert], [:desert,:bears], [:desert, :bears], [:forest]],
    ],
    tile2: [
      [[:swamp, :cougars], [:forest, :cougars], [:forest, :cougars], [:forest], [:forest], [:forest]],
      [[:swamp], [:swamp], [:forest], [:desert], [:desert], [:desert]],
      [[:swamp], [:mountain], [:mountain], [:mountain], [:mountain], [:desert]],
    ],
    tile3: [
      [[:swamp], [:swamp], [:forest], [:forest], [:forest], [:water]],
      [[:swamp, :cougars], [:swamp, :cougars], [:forest], [:mountain], [:water], [:water]],
      [[:mountain, :cougars], [:mountain], [:mountain], [:mountain], [:water], [:water]],
    ],
    tile4: [
      [[:desert], [:desert], [:mountain], [:mountain], [:mountain], [:mountain]],
      [[:desert], [:desert], [:mountain], [:water], [:water], [:water, :cougars]],
      [[:desert], [:desert], [:desert], [:forest], [:forest], [:forest, :cougars]],
    ],
    tile5: [
      [[:swamp], [:swamp], [:swamp], [:mountain], [:mountain], [:mountain]],
      [[:swamp], [:desert], [:desert], [:water], [:mountain], [:mountain, :bears]],
      [[:desert], [:desert], [:water], [:water], [:water], [:water, :bears]],
    ],
    tile6: [
      [[:desert, :bears], [:desert], [:swamp], [:swamp], [:swamp], [:forest]],
      [[:mountain, :bears], [:mountain], [:swamp], [:swamp], [:forest], [:forest]],
      [[:mountain], [:water], [:water], [:water], [:water], [:forest]],
    ],
  }



  ### Clues

  class Clue
    class << self
      def all_clues(mode)
        clues = []
        terrain_pairs = TERRAINS.product(TERRAINS).select{ |a,b| a < b }

        clues += terrain_pairs.map { |a, b| Clue.new("either #{a} or #{b}", [a, b], within(0)) }
        clues += TERRAINS.map { |t| Clue.new("within 1 of #{t}", [t], within(1)) }
        clues << Clue.new("within 1 of animal territory", ANIMALS, within(1))
        clues << Clue.new("within 2 of a standing stone", mode.stones, within(2))
        clues << Clue.new("within 2 of an abandoned shack", mode.shacks, within(2))
        clues << Clue.new("within 2 of bear territory", [:bears], within(2))
        clues << Clue.new("within 2 of cougar territory", [:cougars], within(2))
        clues << Clue.new("within 3 of blue structure", BLUE_STRUCTURES, within(3))
        clues << Clue.new("within 3 of green structure", GREEN_STRUCTURES, within(3))
        clues << Clue.new("within 3 of white structure", WHITE_STRUCTURES, within(3))
        if mode.include_black?
          clues << Clue.new("within 3 of black structure", BLACK_STRUCTURES, within(3))
        end

        if mode.include_not?
          clues += terrain_pairs.map { |a, b| Clue.new("neither #{a} nor #{b}", [a, b], not_within(0)) }
          clues += TERRAINS.map { |t| Clue.new("not within 1 of #{t}", [t], not_within(1)) }
          clues << Clue.new("not within 1 of animal territory", ANIMALS, not_within(1))
          clues << Clue.new("not within 2 of a standing stone", mode.stones, not_within(2))
          clues << Clue.new("not within 2 of an abandoned shack", mode.shacks, not_within(2))
          clues << Clue.new("not within 2 of bear territory", [:bears], not_within(2))
          clues << Clue.new("not within 2 of cougar territory", [:cougars], not_within(2))
          clues << Clue.new("not within 3 of blue structure", BLUE_STRUCTURES, not_within(3))
          clues << Clue.new("not within 3 of green structure", GREEN_STRUCTURES, not_within(3))
          clues << Clue.new("not within 3 of white structure", WHITE_STRUCTURES, not_within(3))
          if mode.include_black?
            clues << Clue.new("not within 3 of black structure", BLACK_STRUCTURES, not_within(3))
          end
        end

        clues
      end

      def matching_clues(mode, board, tokens)
        tokens.reduce(all_clues(mode)) do |clues, entry|
          pos, matches = entry
          clues.select { |clue| clue.check(board, pos) == matches }
        end
      end

      private

      def within(d)
        lambda { |x| x <= d }
      end

      def not_within(d)
        lambda { |x| x > d }
      end
    end

    attr_reader :text, :elements, :predicate

    def initialize(text, elements, predicate)
      @text = text
      @elements = elements
      @predicate = predicate
    end

    def check(board, pos)
      predicate.call(elements.map { |e| board.distance(pos, e) }.min)
    end
  end

  class << self
    ### Rendering

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

      rvg = Magick::RVG.new(1000,1000).viewbox(0,0,1000,1000) do |canvas|
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
