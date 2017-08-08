#!/usr/bin/env ruby
require 'byebug'

AB_DEPTH = 8

class Board
  include Enumerable

  def initialize(m) # rows
    raise ArgumentError, 'non-square matrix' if m.map(&:size).uniq.size != 1 || m.map(&:size).uniq.first != m.size
    @m = m
  end

  # alternate constructor for empty board
  def self.empty(arity = 3)
    new((0..arity - 1).map { [nil].cycle(arity) }.map(&:to_a))
  end

  # mark cell on board with some token.
  # mutative. does bounds checking and "is this spot taken" checking
  def mark!(row, col, player)
    return false if invalid_indices(row, col) || !@m[row][col].nil?
    @m[row][col] = player
    true
  end

  # non-mutative version of mark!
  # will fail silently for invalid placements.
  # used in minimax search.
  def mark(row, col, player)
    new_board = Board.new(@m.map(&:dup))
    new_board.mark!(row, col, player)
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

  # does this board have a winner?
  # check if there is a winning row, then if there is a winning column, then diagonal.
  # returns token of the winner
  def winner
    win_rows = rows.select { |r| r.all? && r.uniq.size == 1 }
    return win_rows[0][0] if !win_rows.empty?
    win_cols = columns.select { |c| c.all? && c.uniq.size == 1 }
    return win_cols[0][0] if !win_cols.empty?
    win_diags = diagonals.select { |d| d.all? && d.uniq.size == 1 }
    return win_diags[0][0] if !win_diags.empty?
    nil
  end

  # pretty-print
  def to_s
    rows.reduce('') do |str, r|
      str + '| ' << r.map { |e| e.nil? ? ' ' : e }.join(' | ') + " |\n"
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
    #   above negated for other player
    # , summed
    heuristic_proc = proc do |acc, row|
      acc += 100 if row.all?   { |c| c == player }
      acc += 10  if row.select { |c| c == player }.size == 2 && row.any?(&:nil?)
      acc += 1   if row.select { |c| c == player }.size == 1 && row.select(&:nil?).size == 2

      acc -= 100 if row.all?   { |c| !c.nil? && c != player}
      acc -= 10  if row.select { |c| !c.nil? && c != player }.size == 2 && row.any?(&:nil?)
      acc -= 1   if row.select { |c| !c.nil? && c != player }.size == 1 && row.select(&:nil?).size == 2

      acc
    end

    rows.reduce(0, &heuristic_proc) + columns.reduce(0, &heuristic_proc) + diagonals.reduce(0, &heuristic_proc)
  end

  private

  def invalid_indices(row, col)
    row.nil? || col.nil? || row > max_ind || col > max_ind || row < 0 || col < 0
  end
end

def calc_alpha_beta(board, depth, alpha, beta, user_player, computer_player, current_player = computer_player)
  return { score: board.heuristic_for_player(computer_player) } if depth == 0 || board.available_cells.empty?
  other_player = current_player == computer_player ? user_player : computer_player
  if current_player == computer_player
    v = { score: -Float::INFINITY }
    board.available_cells.map do |(r, c)|
      v_prime = calc_alpha_beta(board.mark(r, c, current_player), depth - 1, alpha, beta, user_player, computer_player, other_player)
      v_prime[:location] = [r, c]
      v = [v, v_prime].max_by { |h| h[:score] }
      alpha = [alpha, v[:score]].max
      break if beta <= alpha
    end
  else
    v = { score: Float::INFINITY }
    board.available_cells.map do |(r, c)|
      v_prime = calc_alpha_beta(board.mark(r, c, current_player), depth - 1, alpha, beta, user_player, computer_player, other_player)
      v_prime[:location] = [r, c]
      v = [v, v_prime].min_by { |h| h[:score] }
      beta = [beta, v[:score]].min
      break if beta <= alpha
    end
  end
  v
end

def calculate_move(board, user_player, computer_player, current_player = computer_player)
  calc_alpha_beta(board, AB_DEPTH, -Float::INFINITY, Float::INFINITY, user_player, computer_player, current_player)
end
