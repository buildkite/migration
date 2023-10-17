# frozen_string_literal: true

require_relative '../../../../lib/bk/compat'

RSpec.describe BK::Compat::GitHubActions do
  context 'it runs a snapshot test on each example' do 
    directory_path = 'examples/gha'

    Dir.glob("#{directory_path}/*.yaml").each do |file|
      next if File.directory?(file)

      file_name = File.basename(file)

      it "compares the generated pipeline for #{file_name} to the original" do
        gha_content = File.read(file)
        parsed_content = BK::Compat::GitHubActions.new(gha_content).parse()

        actual = JSON.parse(parsed_content.to_h.to_json).to_yaml
        expect(actual).to match_snapshot(file_name)
      end
    end  
  end
end
