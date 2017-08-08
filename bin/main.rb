#!/usr/bin/env ruby

require 'optparse'
require_relative '../lib/player.rb'
require_relative '../lib/board.rb'

def interact(options)
  loop do
    # assign player tokens
    puts "do you want to be X or O [x/O]"
    human_player = HumanPlayer.new(gets.chomp.downcase == 'x' ? 'X' : 'O')
    computer_player = ComputerPlayer.new(human_player.to_s == 'X' ? 'O' : 'X')
    puts "you are #{human_player}"

    board = Board.empty(options[:board_size], human_player, computer_player)

    players = [human_player, computer_player]
    # computer maybe goes first
    if rand(2).zero?
      puts 'computer going first..'
      players.reverse!
    end

    while !board.game_over?
      catch :game_loop do
        players.each do |player|
          moved_validly = player.play_turn(board, options[:search_depth])
          if !moved_validly
            puts 'invalid move'
            throw :game_loop
          end
          # break early if user just won
          throw :game_loop if board.game_over?
        end
      end
    end

    if board.winner
      puts "winner: #{board.winner} (#{board.winner.class})"
    else
      puts "it's a tie"
    end
    puts board

    puts 'do you want to play again? [y/N]'
    break if gets.chomp != 'y'
  end
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
