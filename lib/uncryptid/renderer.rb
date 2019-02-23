# frozen_string_literal: true

module Uncryptid
  class Renderer
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
      blue_shack: ["SteelBlue1", :triangle],
      blue_stone: ["SteelBlue1", :octagon],
      green_shack: ["chartreuse", :triangle],
      green_stone: ["chartreuse", :octagon],
      white_shack: ["white", :triangle],
      white_stone: ["white", :octagon],
      black_shack: ["black", :triangle],
      black_stone: ["black", :octagon],
    }
    DY = Math.sqrt(3) / 2.0
    SIZE = 50

    def self.render(board, filename)
      new(board).render!(filename)
    end

    def initialize(board)
      @board = board
    end

    def render!(filename)
      rvg = Magick::RVG.new(1000, 1000).viewbox(0, 0, 1000, 1000) do |canvas|
        canvas.background_fill = "white"
        canvas.translate(87, 131)

        Board::HEIGHT.times do |y|
          Board::WIDTH.times do |x|
            cell = @board[Point.new(y, x)]
            next unless cell.type

            canvas.g.translate(SIZE * x * 1.5, SIZE * DY * (y * 2 + x % 2)) do |body|
              render_cell(cell, body)
            end
          end
        end
      end
      rvg.draw.write(filename)
    end

    private

    def render_cell(cell, body)
      body.styles(fill: TERRAIN_COLORS[cell.type], stroke: "white", stroke_width: 4)
      hexagon(body, SIZE)
      ANIMALS.each do |a|
        next unless cell.distances[a] == 0
        body.g do |marker|
          marker.styles(fill_opacity: 0, stroke: ANIMAL_COLORS[a], stroke_width: 3)
          hexagon(marker, SIZE * 0.8)
        end
      end
      ALL_STRUCTURES.each do |s|
        next unless cell.distances[s] == 0

        color, shape = STRUCTURE_PROPERTY[s]
        case shape
        when :triangle
          triangle(body, color, SIZE * 0.3)
        when :octagon
          octagon(body, color, SIZE * 0.3)
        end
      end
    end

    def hexagon(body, size)
      body.polygon(
        -1.0 * size,  0,
        -0.5 * size,  DY * size,
         0.5 * size,  DY * size,
         1.0 * size,  0,
         0.5 * size, -DY * size,
        -0.5 * size, -DY * size
      )
    end

    def triangle(body, color, size)
      body.g.rotate(90) do |t|
        t.styles(fill: color, stroke: "black", stroke_width: 1)
        t.polygon(
          -1.0 * size,  0,
           0.5 * size,  DY * size,
           0.5 * size, -DY * size
        )
      end
    end

    def octagon(body, color, size)
      r45 = Math.sqrt(2) / 2
      body.g.rotate(22.5) do |t|
        t.styles(fill: color, stroke: "black", stroke_width: 1)
        t.polygon(
          -1.0 * size, 0,
          -r45 * size, r45 * size,
          0,           1.0 * size,
          r45 * size,  r45 * size,
          1.0 * size,  0,
          r45 * size, -r45 * size,
          0,          -1.0 * size,
          -r45 * size, -r45 * size
        )
      end
    end
  end
end
