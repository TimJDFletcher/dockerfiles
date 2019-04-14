# spec/baseimage_spec.rb

require "serverspec"
require "docker"

describe "Dockerfile" do
  before(:all) do
    image = Docker::Image.build_from_dir('.')

    set :os, family: :debian
    set :backend, :docker
    set :docker_image, image.id
  end

  it "installs the right version of Debain" do
    expect(os_version).to include("Debian GNU/Linux buster/sid")
  end

  describe file('/entrypoint') do
    it { should exist }
    it { should be_file }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
  end

  describe package('samba') do
    it { should be_installed }
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

  def os_version
    command("cat /etc/os-release").stdout
  end

end
