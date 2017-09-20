# frozen_string_literal: true

RSpec.describe Iface::ValueSet::Pair do
  describe '::new' do
    context 'bad syntax' do
      it 'raises an ArgumentError' do
        expect { described_class.new('foo') }.to raise_error(ArgumentError)
        expect { described_class.new('FOO') }.to raise_error(ArgumentError)
      end
    end

    context 'good syntax' do
      it 'parses the text correctly' do
        [
          %w[FOO=bar FOO bar],
          %w[FOO="baz" FOO baz],
          ['FOO= baz', 'FOO', ' baz']
        ].each do |text, name, value|
          pair1 = described_class.new(text)
          expect(pair1.name).to eq name
          expect(pair1.value).to eq value
        end
      end
    end
  end

  describe '#to_s' do
    it 'returns NAME=value' do
      [
        %w[FOO=bar FOO="bar"],
        %w[FOO="baz" FOO="baz"],
        ['FOO= baz', 'FOO=" baz"']
      ].each do |text, result|
        expect(described_class.new(text).to_s).to eq result
      end
    end
  end
end

RSpec.describe Iface::ValueSet do
  let(:value_set) do
    described_class.new(StringIO.new(<<~__EOF__))
      FOO=bar
      BAR="baz"
      PHRED=smerd
    __EOF__
  end

  describe '#[]' do
    context 'name exists' do
      it 'returns the value' do
        expect(value_set['foo']).to eq 'bar'
        expect(value_set['bar']).to eq 'baz'
        expect(value_set['PHRED']).to eq 'smerd'
      end
    end

    context 'name does not exist' do
      it 'returns nil' do
        expect(value_set['baz']).to be_nil
        expect(value_set['smerd']).to be_nil
      end
    end
  end

  describe '#key?' do
    context 'name exists' do
      it 'returns true' do
        expect(value_set.key?('foo')).to eq true
        expect(value_set.key?('bar')).to eq true
        expect(value_set.key?('PHRED')).to eq true
      end
    end

    context 'name does not exist' do
      it 'returns nil' do
        expect(value_set.key?('baz')).to eq false
        expect(value_set.key?('smerd')).to eq false
      end
    end
  end

  describe '#to_s' do
    it 'returns a deserialized list of NAME=value pairs' do
      expect(value_set.to_s).to eq %(FOO="bar"\nBAR="baz"\nPHRED="smerd")
    end
  end
end
