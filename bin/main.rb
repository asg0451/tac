#!/usr/bin/env ruby

require 'optparse'
require_relative '../lib/tac.rb'

def interact(options)
  loop do
    board = Board.empty(options[:board_size])

    # assign player tokens
    puts "do you want to be X or O [x/O]"
    user_player = (gets.chomp.downcase == 'x' ? 'X' : 'O')
    computer_player = user_player == 'X' ? 'O' : 'X'
    puts "you are #{user_player}"

    # computer maybe goes first
    if rand(2).zero?
      puts 'computer going first..'
      computer_turn(board, user_player, computer_player, options[:search_depth])
    end

    while board.winner.nil? && !board.available_cells.empty?
      moved_validly = user_turn(board, user_player)
      if !moved_validly
        puts 'invalid move'
        next
      end
      computer_turn(board, user_player, computer_player, options[:search_depth])
    end

    if board.winner
      puts "winner: #{board.winner}"
    else
      puts "it's a tie"
    end
    puts board

    puts 'do you want to play again? [y/N]'
    break if gets.chomp != 'y'
  end
end

def user_turn(board, user_player)
  puts board
  puts 'enter move: row,column (zero-indexed)'
  r, c = gets.chomp.split(',').map(&:to_i)
  board.mark!(r, c, user_player)
end

def computer_turn(board, user_player, computer_player, search_depth)
  # cheat slightly if the board is empty: place a token somewhere random
  return board.mark!(rand(board.size), rand(board.size), computer_player) if board.empty?

  move = calculate_move(board, user_player, computer_player, computer_player, search_depth)
  return if move[:location].nil?
  board.mark!(move[:location][0], move[:location][1], computer_player)
end

###

Signal.trap("INT") do
  puts 'exiting..'
  exit
end

options = { board_size: 3, search_depth: 4 }
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-b", "--board-size N", "Board Size (Default is 3. Warning: sizes > 4 can be real slow)") do |b|
    options[:board_size] = b.to_i
  end
  opts.on("-d", "--search-depth N", "Search Depth (Default is 4. Increase to make AI better but slower)") do |d|
    options[:search_depth] = d.to_i
  end
end.parse!

interact(options)
