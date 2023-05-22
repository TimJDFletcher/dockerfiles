require 'dockerspec'
require 'dockerspec/serverspec'
require 'docker'
require 'docker/compose'

def compose
  @compose ||= Docker::Compose.new
end

describe 'Samba Timemachine Container' do
  before(:all) do
    set :backend, :docker
    set :docker_container, 'samba-timemachine'
    ENV['PUID'] = '1234'
    ENV['PGID'] = '4321'
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

  context 'File-related tests' do
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
      # test the config file directly due to this: https://lists.samba.org/archive/samba-technical/2017-August/122522.html
      its(:content) { should contain('log level               = 4') } 
    end

    describe file('/etc/samba/users.map') do
      it { should exist }
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should contain('testuser = testuser') }
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
      its(:content) { should contain('1324997410816') }
    end

    describe file('/backups') do
      it { should exist }
      it { should be_directory }
      it { should be_mode 700 }
      it { should be_owned_by 'testuser' }
      it { should be_grouped_into 'testuser' }
    end
  end

  context 'User and group tests' do
    describe group('testuser') do
      it { should exist }
      it { should have_gid '4321' }
    end

    describe user('testuser') do
      it { should exist }
      it { should have_uid '1234' }
      it { should belong_to_group '4321' }
    end
  end

  context 'Process-related tests' do
    describe command('/usr/bin/testparm --verbose') do
      its(:stderr) { should contain('Loaded services file OK') }
      its(:stdout) { should contain('max disk size = 1263616') }
      its(:stdout) { should contain('fruit:time machine max size = 1263616 MB') }
      its(:exit_status) { should eq 0 }
    end

    describe command('/usr/bin/smbpasswd -e testuser') do
      its(:stdout) { should contain('Enabled user testuser.') }
      its(:exit_status) { should eq 0 }
    end

    describe process('smbd') do
      it { should be_running }
      its(:args) { should contain('--no-process-group --foreground --debug-stdout') }
      its(:user) { should eq('root') }
    end
  end
  context 'Network tests' do
    describe file('/proc/1/net/tcp') do
      it { should exist }
      its(:content) { should contain('00000000:01BD') }
    end
  end
end
