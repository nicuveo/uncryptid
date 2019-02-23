# frozen_string_literal: true

module Uncryptid
  class Board
    WIDTH = 12
    HEIGHT = 9

    class << self
      def create(t1, t2, t3, t4, t5, t6, elements = {})
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
          queue += Board.neighbours(current).map { |p| [p, d + 1]}
        end
      end
    end
  end
end
