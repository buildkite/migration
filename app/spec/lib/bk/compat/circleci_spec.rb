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
end

RSpec.describe BK::Compat::CircleCISteps::DockerInstaller do
  describe 'Docker installation parameters' do
    context 'with no parameters' do
      let(:installer) { described_class.new({}) }

      it 'uses simple installation' do
        result = installer.install_commands

        expect(result).to include("echo '~~~ Installing Docker'")
        expect(result).to include('curl -fsSL https://get.docker.com -o get-docker.sh')
        expect(result).to include('sh get-docker.sh')
        expect(result.size).to eq(3) # Should only have these 3 commands
      end
    end

    context 'with install-dir parameter' do
      let(:installer) { described_class.new({ 'install-dir' => '/custom/path' }) }

      it 'creates custom directory and installs there' do
        result = installer.install_commands

        expect(result).to include('$SUDO mkdir -p /custom/path')
        expect(result).to include('if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi')
      end

      it 'uses default installation method with custom directory' do
        result = installer.install_commands

        expect(result).to include('curl -fsSL https://get.docker.com -o get-docker.sh')
        expect(result).to include('sh get-docker.sh')
      end
    end

    context 'with version parameter' do
      let(:installer) { described_class.new({ 'version' => 'v20.10.23' }) }

      it 'installs specific version' do
        result = installer.install_commands

        expect(result).to include('VERSION=v20.10.23')
        expect(result).to include(
          'curl -fsSL https://download.docker.com/linux/static/stable/x86_64/' \
          'docker-${VERSION}.tgz -o docker.tgz'
        )
        expect(result).to include('tar xzvf docker.tgz')
        expect(result).to include('rm -rf docker docker.tgz')
      end

      it 'uses default installation directory' do
        result = installer.install_commands

        expect(result).to include('$SUDO cp docker/* /usr/local/bin/')
      end
    end

    context 'with both version and install-dir parameters' do
      let(:installer) do
        described_class.new({
                              'version' => 'v20.10.23',
                              'install-dir' => '/opt/docker'
                            })
      end

      it 'combines both custom directory and version installation' do
        result = installer.install_commands

        expect(result).to include('$SUDO mkdir -p /opt/docker')
        expect(result).to include('VERSION=v20.10.23')
        expect(result).to include('$SUDO cp docker/* /opt/docker/')
      end
    end

    context 'with default parameter values' do
      let(:installer) do
        described_class.new({
                              'install-dir' => '/usr/local/bin',
                              'version' => 'latest'
                            })
      end

      it 'uses simple installation when defaults are specified explicitly' do
        result = installer.install_commands

        expect(result).to eq([
                               "echo '~~~ Installing Docker'",
                               'curl -fsSL https://get.docker.com -o get-docker.sh',
                               'sh get-docker.sh'
                             ])
      end
    end

    context 'with invalid parameters' do
      let(:installer) { described_class.new({ 'unknown' => 'value' }) }

      it 'ignores unknown parameters' do
        result = installer.install_commands

        expect(result).to eq([
                               "echo '~~~ Installing Docker'",
                               'curl -fsSL https://get.docker.com -o get-docker.sh',
                               'sh get-docker.sh'
                             ])
      end
    end
  end
end

RSpec.describe BK::Compat::CircleCISteps::DockerOrb do
  let(:docker_orb) { described_class.new }

  describe '#translator' do
    it 'delegates docker/install-docker to DockerInstaller' do
      config = { 'version' => 'v20.10.23' }
      installer = instance_double(BK::Compat::CircleCISteps::DockerInstaller)

      expect(BK::Compat::CircleCISteps::DockerInstaller).to receive(:new)
        .with(config)
        .and_return(installer)
      expect(installer).to receive(:install_commands)
        .and_return(%w[some commands])

      result = docker_orb.translator('docker/install-docker', config)
      expect(result).to eq(%w[some commands])
    end

    it 'handles docker/build command' do
      config = { 'image' => 'myapp', 'tag' => 'v1.0' }
      result = docker_orb.translator('docker/build', config)

      expect(result).to include('docker build -t myapp:v1.0 .')
    end

    it 'handles unsupported docker commands' do
      result = docker_orb.translator('docker/unsupported', {})

      expect(result).to eq(['# Unsupported docker orb action: docker/unsupported'])
    end
  end
end
