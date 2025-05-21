# frozen_string_literal: true

require_relative '../../../../lib/bk/compat'

RSpec.describe BK::Compat::Jenkins do
  let(:jenkins) { BK::Compat::Jenkins }

  context 'it runs a snapshot test on each example' do
    directory_path = 'examples/jenkins'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        jenkins_content = File.read(file)
        parsed_content = jenkins.new(jenkins_content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
end
