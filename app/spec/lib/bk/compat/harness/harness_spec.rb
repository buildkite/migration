# frozen_string_literal: true

require_relative '../../../../../lib/bk/compat/parsers/harness'

RSpec.describe BK::Compat::Harness do
  let(:harness) { BK::Compat::Harness }

  context 'it runs a snapshot test on each example' do
    directory_path = 'spec/lib/bk/compat/harness/examples'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        content = File.read(file)
        parsed_content = harness.new(content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
end
