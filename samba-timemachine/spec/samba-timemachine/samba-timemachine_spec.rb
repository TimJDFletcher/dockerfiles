require 'docker'
require 'serverspec'
require 'spec_helper'

# Define packages
packages = {
  'samba' => {
    version: '2:4.9.5+dfsg-3'
  },
  'samba-vfs-modules' => {
    version: '2:4.9.5+dfsg-3'
  }
}

describe 'Samba Timemachine Container' do
  before(:all) do
    image = Docker::Image.build_from_dir('.')
    set :env, { "PUID" => "1234"}
    @container = image.run()
    set :os, family: :debian
    set :backend, :docker
    set :docker_container, @container.id
  end

  describe file('/etc/os-release') do
    its(:content) { is_expected.to match(/"Debian GNU\/Linux buster\/sid"/) }
  end

  packages.each do |name, details|
    describe package(name) do
      it { should be_installed.with_version(details[:version]) }
    end
  end

  describe user('timemachine') do
    it { should exist }
  end

  describe file('/etc/samba/smb.conf') do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
  end

  describe command('/usr/bin/testparm') do
    its(:stderr) { should match(/Loaded services file OK/) }
    its(:exit_status) { should eq 0 }
  end

  describe command('smbpasswd -e timemachine') do
    its(:stdout) { should match(/Enabled user timemachine./) }
    its(:exit_status) { should eq 0 }
  end

  describe file('/entrypoint') do
    it { should exist }
    it { should be_file }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
  end

  describe process('smbd') do
    it { is_expected.to be_running }
    its(:args) { is_expected.to contain('--no-process-group --log-stdout --foreground') }
    its(:user) { is_expected.to eq('root') }
  end

  describe command('ss -tulpn') do
    its(:stdout) { should match(/^tcp.*0.0.0.0:445.*\"smbd\",pid=1/)}
    its(:exit_status) { should eq 0 }
  end

  after(:all) do
     @container.kill
     @container.delete(:force => true)
  end
end
