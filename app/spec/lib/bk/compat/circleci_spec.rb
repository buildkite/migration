# frozen_string_literal: true

require_relative '../../../../lib/bk/compat'

RSpec.describe BK::Compat::CircleCI do
  let(:circleci) { BK::Compat::CircleCI }

  context 'it runs a snapshot test on each example' do
    directory_path = 'examples/circleci'

    Dir.glob("#{directory_path}/*").each do |file|
      next if File.directory?(file)

      it "compares the generated pipeline for #{file} to the original" do
        circleci_content = File.read(file)
        parsed_content = circleci.new(circleci_content).parse

        actual = parsed_content.render(colors: false)
        expect(actual).to match_snapshot(file)
      end
    end
  end
  describe 'docker/install-docker parameters' do
    let(:docker_orb) { BK::Compat::CircleCISteps::DockerOrb.new }

    context 'with no parameters' do
      let(:config) { {} }

      it 'uses simple installation' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to include("echo '~~~ Installing Docker'")
        expect(result).to include('curl -fsSL https://get.docker.com -o get-docker.sh')
        expect(result).to include('sh get-docker.sh')
        expect(result.size).to eq(3)  # Should only have these 3 commands
      end
    end

    context 'with install-dir parameter' do
      let(:config) { { 'install-dir' => '/custom/path' } }

      it 'creates custom directory and installs there' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to include('$SUDO mkdir -p /custom/path')
        expect(result).to include('if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi')
      end

      it 'uses default installation method with custom directory' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to include('curl -fsSL https://get.docker.com -o get-docker.sh')
        expect(result).to include('sh get-docker.sh')
      end
    end

    context 'with version parameter' do
      let(:config) { { 'version' => 'v20.10.23' } }

      it 'installs specific version' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to include('VERSION=v20.10.23')
        expect(result).to include('curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz -o docker.tgz')
        expect(result).to include('tar xzvf docker.tgz')
        expect(result).to include('rm -rf docker docker.tgz')
      end

      it 'uses default installation directory' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to include('$SUDO cp docker/* /usr/local/bin/')
      end
    end

    context 'with both version and install-dir parameters' do
      let(:config) { { 'version' => 'v20.10.23', 'install-dir' => '/opt/docker' } }

      it 'combines both custom directory and version installation' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to include('$SUDO mkdir -p /opt/docker')
        expect(result).to include('VERSION=v20.10.23')
        expect(result).to include('$SUDO cp docker/* /opt/docker/')
      end
    end

    context 'with default parameter values' do
      let(:config) { { 'install-dir' => '/usr/local/bin', 'version' => 'latest' } }

      it 'uses simple installation when defaults are specified explicitly' do
        result = docker_orb.translator('docker/install-docker', config)
        
        expect(result).to eq([
          "echo '~~~ Installing Docker'",
          'curl -fsSL https://get.docker.com -o get-docker.sh',
          'sh get-docker.sh'
        ])
      end
    end

    context 'with invalid parameters' do
      it 'ignores unknown parameters' do
        result = docker_orb.translator('docker/install-docker', { 'unknown' => 'value' })
        
        expect(result).to eq([
          "echo '~~~ Installing Docker'",
          'curl -fsSL https://get.docker.com -o get-docker.sh',
          'sh get-docker.sh'
        ])
      end
    end
  end  
end
