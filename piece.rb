require 'byebug'

class Piece

  RENDER_COLOR = {
    :white => :green,
    :black => :red
  }

  attr_reader :color
  attr_accessor :pos, :moved

  def initialize(board, color, pos)
    @pos = pos
    @color = color
    @board = board
    @moved = false
  end

  def valid_moves
    moves.select do |move|
      board_dup = @board.dup
      begin
        board_dup.move(@pos,move)
      rescue RuntimeError => e
        puts "IN OUR RESCUE!!!!!!"

        puts e.message
        puts e.backtrace
        exit(0)
      end
      !board_dup.in_check?(@color)
    end
  end

  def self.add_positions(*positions)
    #[pos[0] + delta[0], pos[1] + delta[1]]
    new_position = Array.new(2, 0)

    positions.each do |pos|
      new_position[0] += pos[0]
      new_position[1] += pos[1]
    end

    new_position
  end

  private
  attr_reader :board

end

class SlidingPiece < Piece

  DELTAS = {
    :horizontal => [ [0,1], [0,-1] ],
    :vertical => [ [1,0], [-1,0] ],
    :down_diag => [ [1,1], [-1,-1] ],
    :up_diag => [ [1,-1], [-1,1] ]
  }

  def moves
    moves = []
    directions = move_dirs
    direction_deltas = []
    if directions.include?(:diagonal)
      up_diag_deltas = DELTAS[:up_diag]
      down_diag_deltas = DELTAS[:down_diag]
      direction_deltas += [up_diag_deltas, down_diag_deltas]
    end

    if directions.include?(:lateral)
      row_deltas = DELTAS[:horizontal]
      col_deltas = DELTAS[:vertical]
      direction_deltas += [row_deltas, col_deltas]
    end

    direction_deltas.each do |deltas|
      # iterate over first set of deltas
      ## up_diag --> down and to the left
      ## down_diag --> down and to the right
      ## horizontal --> to the right
      ## vertical --> down
      delta1, delta2 = deltas
      self.check_along_direction(moves, delta1)

      # iterate over the second set of deltas
      ## up_diag --> up and to the right
      ## down_diag --> up and to the left
      ## horizontal --> to the left
      ## vertical --> up
      self.check_along_direction(moves, delta2)
    end

    moves
  end

  def move_dirs
    []
  end

  protected
  def check_along_direction(moves, delta)
    current_pos = Piece.add_positions(@pos, delta)
    while @board.in_bounds?(current_pos)
      unless board[current_pos].nil?
        piece_here = @board[current_pos]
        moves << current_pos unless piece_here.color == self.color
        break
      end
      moves << current_pos

      current_pos = Piece.add_positions(current_pos, delta)
    end
  end

end

class Bishop < SlidingPiece
  def move_dirs
    [:diagonal]
  end

  def to_s
    "B"
  end
end

class Rook < SlidingPiece
  def move_dirs
    [:lateral]
  end

  def to_s
    "R"
  end
end

class Queen < SlidingPiece
  def move_dirs
    [:diagonal, :lateral]
  end

  def to_s
    "Q"
  end

end

class SteppingPiece < Piece

  DELTAS = {
    :up => [-1, 0],
    :down => [1, 0],
    :left => [0, -1],
    :right => [0, 1],
    :upright => [-1, 1],
    :downright => [1, 1],
    :downleft => [1, -1],
    :upleft => [-1, -1]
  }

  def moves_helper(deltas)
    moves = []

    deltas.each do |delta|
      potential_move = Piece.add_positions(@pos, delta)
      if @board.in_bounds?(potential_move)
        piece = @board.piece_here(potential_move)
        if piece.nil? || piece.color != self.color
          moves << potential_move
        end
      end
    end

    moves
  end
end

class King < SteppingPiece
  # Make sure to account for moving into check
  def moves
    moves_helper(SteppingPiece::DELTAS.values)
  end

  def to_s
    "K"
  end
end

class Knight < SteppingPiece

  MOVES = [
    Piece.add_positions(DELTAS[:up], DELTAS[:up], DELTAS[:right]),
    Piece.add_positions(DELTAS[:up], DELTAS[:up], DELTAS[:left]),
    Piece.add_positions(DELTAS[:up], DELTAS[:left], DELTAS[:left]),
    Piece.add_positions(DELTAS[:up], DELTAS[:right], DELTAS[:right]),

    Piece.add_positions(DELTAS[:down], DELTAS[:right], DELTAS[:right]),
    Piece.add_positions(DELTAS[:down], DELTAS[:left], DELTAS[:left]),
    Piece.add_positions(DELTAS[:down], DELTAS[:down], DELTAS[:right]),
    Piece.add_positions(DELTAS[:down], DELTAS[:down], DELTAS[:left])
  ]

  def moves
    moves_helper(Knight::MOVES)
  end

  def to_s
    "N"
  end

end


class Pawn < SteppingPiece

  def moves

    moves = []

    delta = color == :white ? DELTAS[:up] : DELTAS[:down]

    front_pos = Piece.add_positions(@pos,delta)

    if @board.in_bounds?(front_pos) && !@board.piece_here(front_pos)
      moves << front_pos

      unless @moved
        two_moves_pos = Piece.add_positions(front_pos, delta)
        unless @board.piece_here(two_moves_pos)
          moves << two_moves_pos
        end
      end
    end

    left_take = Piece.add_positions(front_pos,DELTAS[:left])
    right_take = Piece.add_positions(front_pos,DELTAS[:right])

    [left_take, right_take].each do |take|
      if @board.in_bounds?(take)
        piece = @board.piece_here(take)
        if @board.in_bounds?(take) && piece && piece.color != self.color
          moves << take
        end
      end
    end

    moves
  end

  def to_s
    "P"
  end

  def dup
    Pawn.new(@board, @color, @pos)
  end

end
