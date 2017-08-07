#!/usr/bin/env ruby
require 'byebug'

class Board
  include Enumerable

  attr_reader :m

  def initialize(m) # rows
    raise ArgumentError, 'non-square matrix' if m.map(&:size).uniq.size != 1 || m.map(&:size).uniq.first != m.size
    @m = m
  end

  def self.empty(arity = 3)
    new((0..arity - 1).map { [nil].cycle(arity) }.map(&:to_a))
  end

  def mark!(row, col, player)
    byebug if row.is_a?(Hash) || col.is_a?(Hash)
    return false if !@m[row][col].nil?
    @m[row][col] = player
    true
  end

  def mark(row, col, player)
    new_board = Board.new(@m.map(&:dup))
    new_board.mark!(row, col, player)
    new_board
  end

  def each(&block)
    @m.each(&block)
  end

  def rows(&block)
    @m.each(&block)
  end

  def columns(&block)
    (0..@m.size - 1).map do |i|
      @m.map { |a| a[i] }
    end.each(&block)
  end

  def diagonals(&block)
    # left -> right diagonal + right -> left diagonal
    (
      [(0..max_ind).map { |i| @m[i][i] }] +
      [(0..max_ind).map { |i| @m[max_ind - i][i] }]
    ).each(&block)
  end

  def max_ind
    @m.size - 1
  end

  def winner
    win_rows = rows.select { |r| r.all? && r.uniq.size == 1 }
    return win_rows[0][0] if !win_rows.empty?
    win_cols = columns.select { |c| c.all? && c.uniq.size == 1 }
    return win_cols[0][0] if !win_cols.empty?
    win_diags = diagonals.select { |d| d.all? && d.uniq.size == 1 }
    return win_diags[0][0] if !win_diags.empty?
    nil
  end

  def to_s
    rows.reduce('') do |str, r|
      str + '| ' << r.map { |e| e.nil? ? ' ' : e }.join(' | ') + " |\n"
    end
  end

  # [ [r,c] ]
  # TODO functionalize
  def available_cells
    cells = []
    rows.each_with_index do |row, ri|
      row.each_with_index do |cell, ci|
        cells << [ri, ci] if cell.nil?
      end
    end
    cells
  end

end

# ## tests todo rspec
# board = Board.new([[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]])
# boardc = Board.new([['X', 'O', nil], ['X', 'O', nil], ['X', nil, nil]])
# boardr = Board.new([['O','O', nil], ['X', 'X', 'X'], [nil, nil, nil]])
# boardd = Board.new([['O','O', nil], ['X', 'O', 'X'], [nil, nil, 'O']])

# puts board.winner
# puts boardc.winner
# puts boardr.winner
# puts boardd.winner
# puts boardc
# ##


# https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning#Improvements_over_naive_minimax

def calculate_move(board, user_player, computer_player, current_player = computer_player)
  other_player = current_player == computer_player ? user_player : computer_player
  available_cells = board.available_cells

  # base cases
  return { score: -10 } if board.winner == user_player
  return { score: 10 }  if board.winner == computer_player
  return { score: 0 }   if available_cells.empty?

  moves = available_cells.map do |(r, c)|
    {
      location: [r, c],
      score: calculate_move(board.mark(r, c, current_player), user_player, computer_player, other_player)[:score]
    }
  end

  if current_player == computer_player
    moves.max_by { |move| move[:score] }
  else
    moves.min_by { |move| move[:score] }
  end
end

def interact
  board = Board.empty
  user_player = rand(2).zero? ? 'X' : 'O'
  computer_player = user_player == 'X' ? 'O' : 'X'
  puts "you are #{user_player}"
  while board.winner.nil?
    puts board
    puts 'enter move: row,column'
    r, c = gets.chomp.split(',').map(&:to_i)
    valid_move = board.mark!(r, c, user_player)
    if !valid_move
      puts 'invalid move'
      next
    end

    # computer go
    move = calculate_move(board, user_player, computer_player, computer_player)
    puts "playing move #{move}"
    break if move&.[](:location).nil?
    board.mark!(move[:location][0], move[:location][1], computer_player)
  end

  if board.winner
    puts "winner: #{board.winner}"
  else
    puts "it's a tie"
  end
  puts board
end

interact
