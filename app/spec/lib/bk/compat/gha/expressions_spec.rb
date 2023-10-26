# frozen_string_literal: true

require 'spec_helper'
require 'parslet/rig/rspec'

require_relative '../../../../../lib/bk/compat/parsers/gha/expressions'

RSpec.describe BK::Compat::ExpressionParser do
  let(:p) { BK::Compat::ExpressionParser.new }
  context 'bools' do
    subject { p.boolean }

    %w[true false].freeze.each do |value|
      it "should parse #{value}" do
        expect(subject).to parse(value)
        expect(p.parse(value)).to include(:bool)
      end
    end
  end

  context 'numbers' do
    subject { p.number }

    {
      integer: '711',
      'negative integer': '-171',
      floats: '-9.2',
      hex: '0xff',
      scientific: '-2.99e-2'
    }.each do |desc, value|
      it "should parse #{desc}" do
        expect(subject).to parse(value)
        expect(p.parse(value)).to include(:num)
      end
    end
  end

  context 'null' do
    it 'should parse null' do
      expect(p.null).to parse('null')
      expect(p.parse('null')).to include(:null)
    end
  end

  context 'string' do
    subject { p.string }

    it 'should parse single quoted strings' do
      expect(subject).to parse('\'string\'')
      expect(p.parse('\'string\'')).to include(:str)

      expect(subject).to parse('\'a\'\'b\'')
      expect(p.parse('\'a\'\'b\'')).to include(:str)
    end

    it 'should parse the empty string' do
      expect(subject).to parse('\'\'')
      expect(p.parse('\'\'')).to include(:str)
    end
  end

  context 'parenthesis' do
    subject { p.parens }

    it 'should parse parenthesised expressions' do
      expect(subject).to parse('(1)')
      expect(p.parse('(1)')).to include(:paren)
    end

    it 'should parse nested parenthesis' do
      expect(subject).to parse('((1))')
      exp = p.parse('((1))')
      expect(exp).to include(:paren)
      expect(exp[:paren]).to include(:paren)
    end
  end

  context 'not' do
    it 'should parse unary not' do
      expect(p.unary_op).to parse('!1')
      expect(p.parse('!1')).to include(:not)
    end
  end

  context 'functions' do
    subject { p.arg_functions }

    func_names = %w[contains startsWith endsWith format join toJSON fromJSON hashFiles].freeze
    arg_amount = %w[() (1) (1,2) (1,2,3,4,5,6)].freeze

    func_names.each do |name|
      it "should parse function #{name}" do
        arg_amount.each do |params|
          funcall = "#{name}#{params}"
          expect(subject).to parse(funcall)

          # make sure it is properly marked in resulting tree
          exp = p.parse(funcall)
          expect(exp).to include(:func)
          expect(exp[:func]).to eq(name)
          expect(exp).to include(:args)
          expect(exp[:args]).to be_a(Array)
        end
        # ensure that without parenthesis it is not valid
        expect { subject.parse(name) }.to raise_error Parslet::ParseFailed
      end
    end
  end

  context 'status functions' do
    subject { p.status_functions }

    status_names = %w[success always cancelled failure].freeze

    status_names.each do |name|
      it "should parse function #{name}" do
        funcall = "#{name}()"
        expect(subject).to parse(funcall)
        exp = p.parse(funcall)
        expect(exp).to include(:status)

        # ensure that without parenthesis it is not valid
        expect { subject.parse(name) }.to raise_error Parslet::ParseFailed
      end
    end
  end

  context 'operations' do
    subject { p.operations }

    ops = %w[<= < >= > == != && ||].freeze
    ops.each do |op|
      it "can parse #{op} operations" do
        value = "1 #{op} 2"
        expect(subject).to parse(value)

        exp = p.parse(value)

        # this is how infix_expressions return stuff
        expect(exp).to include(:l)
        expect(exp).to include(:r)
        expect(exp).to include(:o)
      end

      it "rejects invalid expressions including #{op}" do
        expect { p.parse("1 #{op}") }.to raise_error Parslet::ParseFailed
        expect { p.parse(op) }.to raise_error Parslet::ParseFailed
        expect { p.parse("#{op} 2") }.to raise_error Parslet::ParseFailed
      end
    end
  end

  context 'contexts' do
    subject { p.context }

    contexts = %w[github inputs job jobs matrix needs runner secrets steps strategy vars].freeze
    contexts.each do |ctx|
      it "can parse #{ctx}" do
        expect(subject).to parse("#{ctx}.one")
        expect(subject).to parse("#{ctx}.one.two1")
        expect(subject).to parse("#{ctx}.*.two.thr2ee")
        expect(subject).to parse("#{ctx}.on_e[sd].*.three")
        expect(subject).to parse("#{ctx}.one.tw-o[1].*")
        expect(subject).to parse("#{ctx}.*._two.*")

        expect { subject.parse("#{ctx}.0invalid") }.to raise_error Parslet::ParseFailed
        expect { subject.parse("#{ctx}.-invalid") }.to raise_error Parslet::ParseFailed
        expect { subject.parse("#{ctx}.") }.to raise_error Parslet::ParseFailed
        expect { subject.parse(ctx) }.to raise_error Parslet::ParseFailed

        expect(p.parse("#{ctx}.one.two")).to include(:context)
      end
    end
  end
end
