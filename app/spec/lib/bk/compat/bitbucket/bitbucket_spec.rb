# frozen_string_literal: true

require_relative '../../../../../lib/bk/compat/parsers/bitbucket'

RSpec.describe BK::Compat::BitBucket do
  let(:bitbucket) { BK::Compat::BitBucket }

  context 'it runs a snapshot test on each branch starting condition pipeline example' do
    directory_path = 'spec/lib/bk/compat/bitbucket/examples/branches'

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

  context 'it runs a snapshot test on each custom starting condition pipeline example' do
    directory_path = 'spec/lib/bk/compat/bitbucket/examples/custom'

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

  context 'it runs a snapshot test on each default starting condition pipeline example' do
    directory_path = 'spec/lib/bk/compat/bitbucket/examples/default'

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

  context 'it runs a snapshot test on each pull-request starting condition pipeline example' do
    directory_path = 'spec/lib/bk/compat/bitbucket/examples/pull-request'

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

  context 'it runs a snapshot test on each tags starting condition pipeline example' do
    directory_path = 'spec/lib/bk/compat/bitbucket/examples/tags'

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
