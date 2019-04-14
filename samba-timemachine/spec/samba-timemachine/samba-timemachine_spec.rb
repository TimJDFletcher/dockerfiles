require 'spec_helper'

# Helpers for RSpec
module Helpers
  def os_version
    command('cat /etc/os-release').stdout
  end

  def compose
    @compose ||= Docker::Compose.new
  end

  def ssh_private_key
    OpenSSL::PKey::RSA.new(2048).to_s

  end
end

RSpec.configure do |c|
  c.wait_timeout = 120

  c.include Helpers
  c.extend Helpers
end

describe 'samba-timemachine Docker container', :extend_helpers do
  set :os, family: :debian
  set :backend, :docker
  set :docker_container, 'samba-timemachine'

  agent_auto_register_key = 'very_secret_key'

  before(:all) do
    ENV['AGENT_AUTO_REGISTER_KEY'] = agent_auto_register_key
    ENV['GOCD_SSH_PRIVATE_KEY'] = ssh_private_key
    ENV['GOCD_TW_DEV_PASSWORD'] = 'qUqP5cyxm6YcTAhz05Hph5gvu9M=' # test

    compose.up('samba-timemachine', detached: true)
    puts 'Waiting for samba-timemachine to become available...'
    wait_for(port(10445)).to be_listening.with('tcp')
    puts 'samba-timemachine is available'
    puts
  end
  after(:all) do
    puts 'Stopping container again'
    compose.kill
    compose.rm(force: true)
  end

  describe user('timemachine') do
    it { should exist }
  end
end
