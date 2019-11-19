require 'serverspec'
require 'docker'

# Define packages
packages = {
  offlineimap: {
    version: '7.2.3+dfsg1-1'
  }
}

describe 'OfflineIMAP Container' do
  before(:all) do
    image = Docker::Image.build_from_dir('.')
    set :backend, :docker
    set :docker_image, image.id
  end

  describe file('/etc/os-release') do
    its(:content) { is_expected.to match(%r{"Debian GNU/Linux 10 \(buster\)"}) }
  end

  packages.each do |name, details|
    describe package(name) do
      it { should be_installed.with_version(details[:version]) }
    end
  end

  describe file('/entrypoint') do
    it { should exist }
    it { should be_file }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
  end

  describe file('/etc/crontab') do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
  end

  describe command('/usr/local/bin/supercronic -test /etc/crontab') do
    its(:exit_status) { should eq 0 }
  end
  describe process('supercronic') do
    it { is_expected.to be_running }
    its(:args) { is_expected.to contain('-json /etc/crontab') }
    its(:user) { is_expected.to eq('offlineimap') }
  end
end
