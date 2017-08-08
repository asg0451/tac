#!/usr/bin/env ruby

require_relative './player.rb'

class Board
  include Enumerable

  attr_reader :human_player, :computer_player

  def initialize(m, human_player = HumanPlayer.new('X'), computer_player = ComputerPlayer.new('O'))
    raise ArgumentError, 'non-square matrix' if m.map(&:size).uniq.size != 1 || m.map(&:size).uniq.first != m.size
    @m = m
    @human_player = human_player
    @computer_player = computer_player
  end

  # alternate constructor for empty board
  def self.empty(arity = 3, human_player = HumanPlayer.new('X'), computer_player = ComputerPlayer.new('O'))
    new((0..arity - 1).map { [nil].cycle(arity) }.map(&:to_a), human_player, computer_player)
  end

  # mark cell on board with some token.
  # mutative. does bounds checking and "is this spot taken" checking
  def mark!(row, col, player)
    return false if invalid_indices(row, col) || !@m[row][col].nil?
    @m[row][col] = player.to_s
    true
  end

  # non-mutative version of mark!
  # will fail silently for invalid placements.
  # used in minimax search.
  def mark(row, col, player)
    new_board = Board.new(@m.map(&:dup), @human_player, @computer_player)
    new_board.mark!(row, col, player.to_s)
    new_board
  end

  # enumerable stuff
  def each(*args, &block)
    @m.each(*args, &block)
  end

  def rows(*args, &block)
    @m.each(*args, &block)
  end

  def columns(*args, &block)
    (0..@m.size - 1).map do |i|
      @m.map { |a| a[i] }
    end.each(*args, &block)
  end

  def diagonals(*args, &block)
    # left -> right diagonal + right -> left diagonal
    (
      [(0..max_ind).map { |i| @m[i][i] }] +
      [(0..max_ind).map { |i| @m[max_ind - i][i] }]
    ).each(*args, &block)
  end

  def empty?
    @m.flatten.none?
  end
  # enumerable stuff ends

  # maximum index of board. used for convenience.
  def max_ind
    @m.size - 1
  end

  def size
    @m.size
  end

  # does this board have a winner?
  # check if there is a winning row, then if there is a winning column, then diagonal.
  # returns the winner or nil if the game is not yet won.
  # a winning row/column/diagonal is one which has no nils and whose elements are all the same.
  # the winner is then the element which is the same.
  def winner
    [rows, columns, diagonals].each do |groups|
      win_groups = groups.select { |g| g.all? && g.uniq.size == 1 }
      return [@human_player, @computer_player].find { |p| p.to_s == win_groups[0][0] } if !win_groups.empty?
    end
    nil
  end

  # pretty-print
  def to_s
    rows.reduce('') do |str, r|
      str + '| ' + r.map { |e| e.nil? ? ' ' : e }.join(' | ') + " |\n"
    end
  end

  # returns list of tuples describing non-marked cells
  # -> [ [r,c] ]
  def available_cells
    cells = []
    rows.each_with_index do |row, ri|
      row.each_with_index do |cell, ci|
        cells << [ri, ci] if cell.nil?
      end
    end
    cells
  end

  # heuristic for a player winning the game given this board
  def heuristic_for_player(player)
    # for each row, col, diag:
    #   +100 for a win, 10 for two (with 1 empty), 1 for single (with 2 empty)
    #   above negated for other player, subtracting 1/10th because it is not their turn (assume it is player's turn)
    # , summed
    heuristic_proc = proc do |acc, row|
      is_player_proc = proc { |c| c == player.to_s }
      acc += 100 if row.all?(&is_player_proc)
      acc += 10  if row.select(&is_player_proc).size == 2 && row.any?(&:nil?)
      acc += 1   if row.select(&is_player_proc).size == 1 && row.select(&:nil?).size == 2

      is_other_player_proc = proc { |c| !c.nil? && c != player.to_s}
      acc -= 90 if row.all?(&is_other_player_proc)
      acc -= 9  if row.select(&is_other_player_proc).size == 2 && row.any?(&:nil?)
      acc -= 0.9   if row.select(&is_other_player_proc).size == 1 && row.select(&:nil?).size == 2

      acc
    end

    rows.reduce(0, &heuristic_proc) + columns.reduce(0, &heuristic_proc) + diagonals.reduce(0, &heuristic_proc)
  end


  def calculate_move(current_player, depth)
    calc_alpha_beta(self, depth, -Float::INFINITY, Float::INFINITY, current_player)
  end

  def game_over?
    !winner.nil? || available_cells.empty?
  end

  private

  def calc_alpha_beta(board, depth, alpha, beta, current_player)
    return { score: board.heuristic_for_player(computer_player) } if depth == 0 || board.available_cells.empty?
    other_player = current_player == @computer_player ? @human_player : @computer_player

    v = { score: current_player.default_v_score }

    board.available_cells.each do |(r, c)|
      v_prime = calc_alpha_beta(board.mark(r, c, current_player), depth - 1, alpha, beta, other_player)
      v_prime[:location] = [r, c]
      v = [v, v_prime].minmax_by { |h| h[:score] }[current_player.minmax_index]
      alpha = [alpha, v[:score]].minmax[current_player.minmax_index]
      break if beta <= alpha
    end
    v
  end

  def invalid_indices(row, col)
    row.nil? || col.nil? || row > max_ind || col > max_ind || row < 0 || col < 0
  end
end
