require 'spec_helper'

# Define packages
packages = {
    postfix: {
      version: '3.5.0-1'
  }
}

def compose
  @compose ||= Docker::Compose.new
end

describe 'Postfix Container' do
  before(:all) do
    set :backend, :docker
    set :docker_container, 'postfix'
    compose.up('postfix', detached: true)
  end

  after(:all) do
    puts 'Stopping container again'
    compose.kill
    compose.rm(force: true)
  end

  describe file('/etc/os-release') do
    its(:content) { is_expected.to match(%r{bullseye}) }
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

  describe process('master') do
    it { is_expected.to be_running }
    its(:args) { is_expected.to contain('-i') }
    its(:user) { is_expected.to eq('root') }
  end

  describe process('pickup') do
    it { is_expected.to be_running }
    its(:user) { is_expected.to eq('postfix') }
  end

  describe process('qmgr') do
    it { is_expected.to be_running }
    its(:user) { is_expected.to eq('postfix') }
  end

  describe command('ss -tulpn') do
    its(:stdout) { should match(/^tcp.*0.0.0.0:25/)}
    its(:exit_status) { should eq 0 }
  end
end
