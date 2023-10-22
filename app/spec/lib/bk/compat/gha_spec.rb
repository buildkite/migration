# frozen_string_literal: true

require_relative '../../../../lib/bk/compat'

RSpec.describe BK::Compat::GitHubActions do
  context 'it runs a snapshot test on each example' do
    directory_path = 'examples/github-actions'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        gha_content = File.read(file)
        parsed_content = BK::Compat::GitHubActions.new(gha_content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
end
