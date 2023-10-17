# frozen_string_literal: true


require_relative '../../../../lib/bk/compat'

RSpec.describe BK::Compat::GitHubActions do
 
  context 'basic.yaml' do 
    let(:subject) do
      gha_content = File.open("examples/gha/basic.yaml").read 
      BK::Compat::GitHubActions.new(gha_content).parse() 
    end
    
    it 'does stuff' do       
      actual = JSON.parse(subject.to_h.to_json).to_yaml
      expect(actual).to match_snapshot('basic.yaml')
    end
  end  
end
