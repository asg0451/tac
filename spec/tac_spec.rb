require_relative '../lib/tac.rb'

RSpec.describe Board, 'Board' do

  context 'constructors' do
    describe '.new' do
      it 'detects bad matrix input' do
        expect { Board.new([[nil, nil]]) }.to raise_error(ArgumentError)
      end
    end

    describe '.empty' do
      it 'produces empty boards of various sizes and has a default argument' do
        b = Board.empty
        expect(b.each.to_a.flatten.size).to eq(9)
        expect(b.each.to_a.flatten.none?).to be true

        b = Board.empty(2)
        expect(b.each.to_a.flatten.size).to eq(4)
        expect(b.each.to_a.flatten.none?).to be true
      end
    end
  end

  describe '#mark!' do
    it 'mutates the board by marking a cell' do
      b = Board.empty
      b.mark!(0, 0, 'X')
      expect(b.each.to_a[0][0]).to eq('X')
    end

    it 'returns false if spot is taken or out of bounds' do
      b = Board.empty
      res = b.mark!(-1, 0, 'X')
      expect(res).to be false

      b.mark!(0, 0, 'X')
      res = b.mark!(0, 0, 'X')
      expect(res).to be false
    end
  end

  context 'enumerable stuff' do
    describe '#each' do
      it 'passes through to row-of-rows representation' do
        b = Board.new([[1, 2], [3, 4]])
        expect(b.each.to_a).to eq([[1,2],[3,4]])
      end
    end

    describe '#rows' do
      it 'passes through to row-of-rows representation' do
        b = Board.new([[1, 2], [3, 4]])
        expect(b.rows.to_a).to eq([[1,2],[3,4]])
      end
    end

    describe '#columns' do
      it 'iterates in column representation' do
        b = Board.new([[1, 2], [3, 4]])
        expect(b.columns.to_a).to eq([[1,3],[2,4]])
      end
    end

    describe '#diagonals' do
      it 'iterates diagonally' do
        b = Board.new([[1, 2], [3, 4]])
        expect(b.diagonals.to_a).to match_array([[1,4],[3,2]])
      end
    end

    describe '#empty?' do
      it 'checks if any cells have been marked' do
        b = Board.empty
        expect(b.empty?).to be true

        b.mark!(0, 0, 'X')
        expect(b.empty?).to be false
      end
    end

    describe '#winner' do
      let(:b) { Board.new([['X', nil], [nil, nil]]) }
      it 'detects no winner when there is none' do
        expect(b.winner).to be_nil
      end

      it 'detects a row winner' do
        b.mark!(0, 1, 'X')
        expect(b.winner).to eq 'X'
      end

      it 'detects a column winner' do
        b.mark!(1, 0, 'X')
        expect(b.winner).to eq 'X'
      end

      it 'detects a diagonal winner' do
        b.mark!(1, 1, 'X')
        expect(b.winner).to eq 'X'
      end
    end

    describe '#available_cells' do
      let(:b) { Board.new([['X', nil], [nil, nil]]) }
      it 'returns available cells' do
        expect(b.available_cells).to match_array([ [0, 1], [1, 0], [1, 1] ])
      end
    end

  end

end
