#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), "../../",  "files", "mcollective", "agent", "nrpe.rb")

describe "nrpe agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../../files/mcollective/agent/nrpe.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("nrpe", :agent_file => agent_file).plugin
  end

  describe "#runcommand" do
    it "should reply with statusmessage 'OK' of exitcode is 0" do
      MCollective::Agent::Nrpe.expects(:run).with("foo", []).returns(0)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_successful
      result.should have_data_items(:exitcode=>0, :perfdata=>"")
      result[:statusmsg].should == "OK"
    end

    it "should reply with statusmessage 'WARNING' of exitcode is 1" do
      MCollective::Agent::Nrpe.expects(:run).with("foo", []).returns(1)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>1, :perfdata=>"")
      result[:statusmsg].should == "WARNING"
    end

    it "should reply with statusmessage 'CRITICAL' of exitcode is 2" do
      MCollective::Agent::Nrpe.expects(:run).with("foo", []).returns(2)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>2, :perfdata=>"")
      result[:statusmsg].should == "CRITICAL"
    end

    it "should reply with statusmessage UNKNOWN if exitcode is something else" do
      MCollective::Agent::Nrpe.expects(:run).with("foo", [])
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>nil, :perfdata=>"")
      result[:statusmsg].should == "UNKNOWN"
    end

    it "should execute `run` with arguments parsed from :args" do
      MCollective::Agent::Nrpe.expects(:run).with("foo",["arg1","arg2"]).returns(0)
      result = @agent.call(:runcommand, :command => "foo", :args => "arg1!arg2")
      result.should be_successful
      result.should have_data_items(:exitcode=>0, :perfdata=>"")
      result[:statusmsg].should == "OK"
    end
  end

  describe "#plugin_for_command" do
    let(:config){mock}
    let(:pluginconf){{"nrpe.conf_dir" => "/foo", "nrpe.conf_file" => "bar.cfg", "nrpe.conf_path" => "/foo:/bar"}}

    before :each do
      config.stubs(:pluginconf).returns(pluginconf)
      MCollective::Config.stubs(:instance).returns(config)
    end

    it "should return the command from nrpe.conf_dir if it is set" do
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[command]=run"])
      MCollective::Agent::Nrpe.plugin_for_command("command", []).should == "run"
    end

    it "should return the command from nrpe.conf_dir if it is set with arguments parsed from :args" do
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[command]=run $ARG1$ $ARG2$"])
      MCollective::Agent::Nrpe.plugin_for_command("command",["60","100"]).should == "run 60 100"
    end

    it "should return the command from nrpe.conf_dir if it is set and nrpe.conf_file and nrpe.conf_path is unset" do
      pluginconf["nrpe.conf_file"] = nil
      pluginconf["nrpe.conf_path"] = nil
      Dir.expects(:glob).with("/foo/*.cfg").returns(["/foo/baz.cfg", "/foo/bar.cfg"])
      File.expects(:exist?).with("/foo/baz.cfg").returns(true)
      File.expects(:readlines).with("/foo/baz.cfg").returns(["command[fake_command]=donotrun"])
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[other_fake_command]=donotrun", "command[command]=run"])
      MCollective::Agent::Nrpe.plugin_for_command("command", []).should == "run"
    end

    it "should return the command from nrpe.conf_path if it is set and nrpe.conf_file is unset" do
      pluginconf["nrpe.conf_file"] = nil
      Dir.expects(:glob).with(["/foo/*.cfg","/bar/*.cfg"]).returns(["/foo/baz.cfg", "/foo/bar.cfg","/bar/baz.cfg"])
      File.expects(:exist?).with("/foo/baz.cfg").returns(true)
      File.expects(:readlines).with("/foo/baz.cfg").returns(["command[fake_command]=donotrun"])
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[other_fake_command]=donotrun"])
      File.expects(:exist?).with("/bar/baz.cfg").returns(true)
      File.expects(:readlines).with("/bar/baz.cfg").returns(["command[command]=run"])
      MCollective::Agent::Nrpe.plugin_for_command("command", []).should == "run"
    end

    it "should return the nil if no matching command is found in nrpe.conf_dir" do
      pluginconf["nrpe.conf_file"] = nil
      pluginconf["nrpe.conf_path"] = nil
      Dir.expects(:glob).with("/foo/*.cfg").returns(["/foo/bar.cfg"])
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[fake_command]=run"])
      MCollective::Agent::Nrpe.plugin_for_command("command", []).should == nil
    end

    it "should return the command from /etc/nagios/nrpe.d if nrpe.conf_dir and nrpe.conf_path is unset" do
      pluginconf["nrpe.conf_dir"] = nil
      pluginconf["nrpe.conf_path"] = nil
      File.expects(:exist?).with("/etc/nagios/nrpe.d/bar.cfg").returns(true)
      File.expects(:readlines).with("/etc/nagios/nrpe.d/bar.cfg").returns(["command[command]=run"])
      MCollective::Agent::Nrpe.plugin_for_command("command", []).should == "run"
    end
  end

  describe "#run" do
    let(:config){mock}
    let(:pluginconf){{"nrpe.conf_dir" => "/foo", "nrpe.conf_file" => "bar.cfg", "nrpe.conf_path" => "/foo:/bar"}}

    before :each do
      config.stubs(:pluginconf).returns(pluginconf)
      MCollective::Config.stubs(:instance).returns(config)
    end

    it "should run the command without sudo when no runas_user is specified" do
      MCollective::Agent::Nrpe.expects(:plugin_for_command).with("foo", []).returns("foo")
      MCollective::Agent::Nrpe.expects(:run_shell_cmd).with("foo").returns([0, "expected output"])
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_successful
    end

    it "should run the command under the user specified in nrpe.cfg" do
      pluginconf["nrpe.runas_user"] = "nrpe"
      MCollective::Agent::Nrpe.expects(:plugin_for_command).with("foo", []).returns("foo")
      MCollective::Agent::Nrpe.expects(:run_shell_cmd).with("sudo -u 'nrpe' foo").returns([0, "expected output"])
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_successful
    end

    it "should run the command found in #plugin_for_command and return output and exitcode" do
      shell = mock
      status = mock

      MCollective::Agent::Nrpe.expects(:plugin_for_command).with("foo", []).returns("foo")
      MCollective::Shell.stubs(:new).returns(shell)
      shell.expects(:runcommand)
      shell.expects(:status).returns(status)
      status.expects(:exitstatus).returns(0)

      MCollective::Agent::Nrpe.run("foo").should == [0, ""]
    end

    it "should return 3 and an error if the command could not be found in #plugin_for_command" do
      MCollective::Agent::Nrpe.expects(:plugin_for_command).with("foo", []).returns(nil)
      MCollective::Agent::Nrpe.run("foo").should == [3, "No such command: foo"]
    end
  end

  describe "#runallcommands" do
    let(:config){mock}
    let(:pluginconf){{"nrpe.conf_dir" => "/foo", "nrpe.conf_file" => "bar.cfg", "nrpe.conf_path" => "/foo:/bar"}}

    before :each do
      config.stubs(:pluginconf).returns(pluginconf)
      MCollective::Config.stubs(:instance).returns(config)
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[command]=run"])
    end

    it "should reply with statusmessage 'OK' of exitcode is 0" do
      MCollective::Agent::Nrpe.expects(:run).with("command").returns(0)
      result = @agent.call(:runallcommands, :command => "command")
      result.should be_successful
      result.should have_data_items(:commands=>{"command"=>{:exitcode=>0, :output=>nil}})
      result[:statusmsg].should == "OK"
      result[:statuscode].should == 0
    end
  end
end
