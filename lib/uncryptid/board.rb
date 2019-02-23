# frozen_string_literal: true

module Uncryptid
  class Board
    WIDTH = 12
    HEIGHT = 9

    TILES = {
      tile1: [
        [[:water], [:water], [:water], [:water], [:forest], [:forest]],
        [[:swamp], [:swamp], [:water], [:desert], [:forest], [:forest]],
        [[:swamp], [:swamp], [:desert], [:desert, :bears], [:desert, :bears], [:forest]],
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

    class << self
      def create(t1, t2, t3, t4, t5, t6, elements = {})
        res = Board.new(width: WIDTH, height: HEIGHT)
        add_tile(res, t1, 0, 0)
        add_tile(res, t2, 0, 6)
        add_tile(res, t3, 3, 0)
        add_tile(res, t4, 3, 6)
        add_tile(res, t5, 6, 0)
        add_tile(res, t6, 6, 6)
        elements.each { |pos, elem| res.add(pos, elem) }

        res
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
              board.set(Location.new(row: row + dy, col: col + dx), type, elements)
            end
          end
        when [:upside_down]
          TILES[name].each_with_index do |line, dy|
            line.each_with_index do |cell, dx|
              elements = cell.dup
              type = elements.shift
              board.set(Location.new(row: row + 2 - dy, col: col + 5 - dx), type, elements)
            end
          end
        else
          raise "unknown tile info: #{ti}"
        end
      end
    end

    attr_reader :height, :width

    def initialize(height: HEIGHT, width: WIDTH)
      @height = height
      @width = width
    end

    def [](pos)
      @data[pos.row * width + pos.col] if include?(pos)
    end

    def include?(pos)
      pos.col >= 0 && pos.col < width &&
        pos.row >= 0 && pos.row < height
    end

    def each
      (0...height).each do |row|
        (0...width).each do |col|
          pos = Location.new(row: row, col: col)
          yield pos, self[pos]
        end
      end
    end
    include Enumerable

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
          queue += current.neighbours.select { |h| include?(h) }.map { |h| [h, d + 1] }
        end
      end
    end
  end
end
