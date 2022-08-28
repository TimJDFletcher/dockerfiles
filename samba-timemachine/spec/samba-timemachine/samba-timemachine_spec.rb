require 'spec_helper'

def compose
  @compose ||= Docker::Compose.new
end

describe 'Samba Timemachine Container' do
  before(:all) do
    set :backend, :docker
    set :docker_container, 'samba-timemachine'
    ENV['PUID'] = '1234'
    ENV['PGID'] = '1234'
    ENV['USER'] = 'testuser'
    ENV['PASS'] = 'Password123'
    ENV['QUOTA'] = '1234'
    ENV['LOG_LEVEL'] = '4'
    compose.up('samba-timemachine', detached: true)
  end

  after(:all) do
    puts 'Stopping container again'
    compose.kill
    compose.rm(force: true)
  end

  describe file('/entrypoint') do
    it { should exist }
    it { should be_file }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
  end

  describe file('/etc/samba/smb.conf') do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    its(:content) { is_expected.to match('max disk size               = 1263616') }
    its(:content) { is_expected.to match('fruit:time machine max size = 1263616 MB') }
    its(:content) { is_expected.to match('log level               = 4') }
  end

  describe file('/etc/samba/users.map') do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { is_expected.to match('timemachine = testuser') }
  end

  describe file('/backups/.com.apple.TimeMachine.supported') do
    it { should exist }
    it { should be_file }
  end

  describe file('/backups/.com.apple.TimeMachine.quota.plist') do
    it { should exist }
    it { should be_file }
    it { should be_mode 444 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { is_expected.to match('1324997410816') }
  end

  describe group('timemachine') do
    it { should exist }
    it { should have_gid '1234' }
  end

  describe user('timemachine') do
    it { should exist }
    it { should have_uid '1234' }
    it { should belong_to_group '1234' }
  end

  describe file('/backups') do
    it { should exist }
    it { should be_directory }
    it { should be_mode 700 }
    it { should be_owned_by 'timemachine' }
    it { should be_grouped_into 'timemachine' }
  end

  describe command('/usr/bin/testparm') do
    its(:stderr) { should match(/Loaded services file OK/) }
    its(:exit_status) { should eq 0 }
  end

  describe command('/usr/bin/smbpasswd -e timemachine') do
    its(:stdout) { should match(/Enabled user timemachine./) }
    its(:exit_status) { should eq 0 }
  end

  describe process('smbd') do
    it { is_expected.to be_running }
    its(:args) { is_expected.to contain('--no-process-group --foreground --debug-stdout') }
    its(:user) { is_expected.to eq('root') }
  end

  describe file('/proc/1/net/tcp') do
    it { should exist }
    its(:content) { is_expected.to match('00000000:01BD') }
  end
end
