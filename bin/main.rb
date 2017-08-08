#!/usr/bin/env ruby

require_relative '../lib/tac.rb'

# change this to change the board size (warning: for size > 3 this gets real slow)
BOARD_SIZE = 3

def interact
  board = Board.empty(BOARD_SIZE)

  # assign player tokens
  puts "do you want to be X or O [x/O]"
  user_player = (gets.chomp.downcase == 'x' ? 'X' : 'O')
  computer_player = user_player == 'X' ? 'O' : 'X'
  puts "you are #{user_player}"

  # computer maybe goes first
  if rand(2).zero?
    puts 'computer going first..'
    computer_turn(board, user_player, computer_player)
  end

  while board.winner.nil? && !board.available_cells.empty?
    moved_validly = user_turn(board, user_player)
    if !moved_validly
      puts 'invalid move'
      next
    end
    computer_turn(board, user_player, computer_player)
  end

  if board.winner
    puts "winner: #{board.winner}"
  else
    puts "it's a tie"
  end
  puts board

  puts 'do you want to play again? [y/N]'
  interact if gets.chomp == 'y'
end

def user_turn(board, user_player)
  puts board
  puts 'enter move: row,column'
  r, c = gets.chomp.split(',').map(&:to_i)
  board.mark!(r, c, user_player)
end

def computer_turn(board, user_player, computer_player)
  # cheat slightly if the board is empty: place a token in the upper left
  return board.mark!(0, 0, computer_player) if board.empty?

  move = calculate_move(board, user_player, computer_player, computer_player)
  return if move[:location].nil?
  board.mark!(move[:location][0], move[:location][1], computer_player)
end

interact
