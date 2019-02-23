# frozen_string_literal: true

module Uncryptid
  class Clue
    class << self
      def all_clues(mode)
        clues = []
        terrain_pairs = TERRAINS.combination(2).to_a

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
end
