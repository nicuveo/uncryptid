# frozen_string_literal: true

module Uncryptid
  class Renderer
    class Point
      attr_reader :x, :y

      def initialize(x:, y:)
        @x = x
        @y = y
      end

      def to_xy
        [x, y]
      end

      def +(other)
        Point.new(x: x + other.x, y: y + other.y)
      end

      def inspect
        "#<Point #{self}>"
      end

      def to_s
        "(#{x}, #{y})"
      end
    end

    TERRAIN_COLORS = {
      forest: "LimeGreen",
      desert: "yellow2",
      mountain: "LightSteelBlue",
      water: "DeepSkyBlue2",
      swamp: "LightPink4",
    }
    ANIMAL_COLORS = {
      bears: "black",
      cougars: "red",
    }
    STRUCTURE_PROPERTY = {
      blue_shack: ["SteelBlue1", 3],
      blue_stone: ["SteelBlue1", 8],
      green_shack: ["chartreuse", 3],
      green_stone: ["chartreuse", 8],
      white_shack: ["white", 3],
      white_stone: ["white", 8],
      black_shack: ["black", 3],
      black_stone: ["black", 8],
    }
    STROKE = {
      terrain: 4.0 / 50.0,
      animal: 3.0 / 50.0,
      structure: 1.0 / 50.0,
    }

    def self.render!(board, filename, width = 1000)
      new(board).render!(filename, width)
    end

    def initialize(board)
      @board = board
    end

    def render!(filename, width)
      height = compute_height!(width)
      stroke_pad_offset = Point.new(
        x: STROKE[:terrain] / Math.sqrt(3.0),
        y: 0.5 * STROKE[:terrain]
      )

      rvg = Magick::RVG.new(width, height).scale(@scale) do |canvas|
        canvas.background_fill = "white"

        @board.each do |loc, cell|
          offset = location_to_point(loc) + stroke_pad_offset
          canvas.g.translate(*offset.to_xy) do |body|
            render_cell(cell, body)
          end
        end
      end
      rvg.draw.write(filename)
    end

    private

    def compute_height!(width)
      rightmost_hex = Location.new(col: @board.width - 1, row: 0)
      draw_width = location_to_point(rightmost_hex).x + 1.0
      # The hexagon strokes extend stroke_length/sqrt(3) units to the left and the right
      draw_width += 2.0 * STROKE[:terrain] * (1.0 / Math.sqrt(3.0))

      bottommost_hex = Location.new(
        # If the board is only 1 tile wide, use column 0 (which is "short"),
        # otherwise there's at least 1 "long" column, let's just use column 1
        col: [1, @board.width - 1].min,
        row: @board.height - 1,
      )
      draw_height = location_to_point(bottommost_hex).y + Math.sin(2.0 * Math::PI / 6.0)
      # Half of the stroke length on the top and bottom of the image
      draw_height += 2.0 * STROKE[:terrain] * 0.5

      @scale = width / draw_width

      width * draw_height / draw_width
    end

    def render_cell(cell, body)
      body.g do |bg|
        bg.styles(fill: TERRAIN_COLORS[cell.type], stroke: "white", stroke_width: STROKE[:terrain])
        polygon(6, bg, 1.0)
      end
      ANIMALS.each do |a|
        next unless cell.distances[a] == 0
        body.g do |marker|
          marker.styles(fill_opacity: 0, stroke: ANIMAL_COLORS[a], stroke_width: STROKE[:animal])
          polygon(6, marker, 0.8)
        end
      end
      ALL_STRUCTURES.each do |s|
        next unless cell.distances[s] == 0

        color, sides = STRUCTURE_PROPERTY[s]
        body.g do |t|
          t.styles(fill: color, stroke: "black", stroke_width: STROKE[:structure])
          polygon(sides, t, 0.3)
        end
      end
    end

    def polygon(sides, body, size)
      body.polygon(*(0...sides).map do |corner|
        angle = 2.0 * Math::PI * corner / sides
        # Put a flat edge on the bottom
        angle += Math::PI * (0.5 + 1.0 / sides)
        [size * Math.cos(angle), size * Math.sin(angle)]
      end.flatten)
    end

    def location_to_point(loc)
      Point.new(
        x: (3.0 / 2.0) * loc.col + 1.0,
        y: Math.sqrt(3.0) * (loc.row + 0.5 * (loc.col & 1) + 0.5),
      )
    end
  end
end
