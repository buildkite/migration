# frozen_string_literal: true

require_relative '../../../../../lib/bk/compat/parsers/circleci'

RSpec.describe BK::Compat::CircleCI do
  let(:circleci) { BK::Compat::CircleCI }

  context 'it runs a snapshot test on each example' do
    directory_path = 'spec/lib/bk/compat/circleci/examples'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        gha_content = File.read(file)
        parsed_content = circleci.new(gha_content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
end
