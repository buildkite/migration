require "spec_helper"

RSpec.describe BK::Compat::CircleCI do
  let(:circleci) { BK::Compat::CircleCI.new }

  context "reactjs.yml" do
    let(:subject) { |e| BK::Compat::CircleCI.parse_file("spec/examples/circleci/#{e.example_group.description}") }

    it "does stuff" do
      puts JSON.parse(subject.to_h.to_json).to_yaml
    end
  end
end
