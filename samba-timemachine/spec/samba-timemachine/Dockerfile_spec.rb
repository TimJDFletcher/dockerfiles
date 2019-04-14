# spec/baseimage_spec.rb

require "serverspec"
require "docker"

# Define packages
packages = {
  'samba' => {
    version: '2:4.9.5+dfsg-3'
  },
  'samba-vfs-modules' => {
    version: '2:4.9.5+dfsg-3'
  }
}

def os_version
  command("cat /etc/os-release").stdout
end

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

  packages.each do |name, details|
    describe package(name) do
      it { should be_installed.with_version(details[:version]) }
    end
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

  describe file('/entrypoint') do
    it { should exist }
    it { should be_file }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
  end
end
