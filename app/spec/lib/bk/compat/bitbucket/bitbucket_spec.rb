# frozen_string_literal: true

require_relative '../../../../../lib/bk/compat'

RSpec.describe BK::Compat::BitBucket do
  let(:bitbucket) { BK::Compat::BitBucket }

  context 'it runs a snapshot test on each example' do
    directory_path = 'spec/lib/bk/compat/bitbucket/examples'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        bb_content = File.read(file)
        parsed_content = bitbucket.new(bb_content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
end
