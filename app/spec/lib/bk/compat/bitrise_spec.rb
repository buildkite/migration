# frozen_string_literal: true

require_relative '../../../../lib/bk/compat'

RSpec.describe BK::Compat::Bitrise do
  let(:bitrise) { BK::Compat::Bitrise }

  context 'it runs a snapshot test on each example' do
    directory_path = 'examples/bitrise'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        bitrise_content = File.read(file)
        parsed_content = bitrise.new(bitrise_content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
end
