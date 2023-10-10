# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BK::Compat::CircleCI do
  let(:circleci) { BK::Compat::CircleCI.new }

  context 'facebook-react.yml' do
    let(:subject) do |e| 
      BK::Compat::CircleCI.new("examples/circleci/#{e.example_group.description}").parse(workflow: 'stable')
    end

    it 'does stuff' do
      #puts JSON.parse(subject.to_h.to_json).to_yaml
    end
  end

  context 'segmentio-aws-okta.yml' do
    let(:subject) do |e|
      BK::Compat::CircleCI.new("examples/circleci/#{e.example_group.description}",
                                      workflow: 'test-dist-publish-linux')
    end

    it 'does stuff' do
      #puts JSON.parse(subject.to_h.to_json).to_yaml
    end
  end
end