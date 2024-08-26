metadata  :name         => "nrpe",
          :description  => "Checks the exit codes of executed Nrpe commands",
          :author      => "R.I.Pienaar <rip@devco.net>",
          :license     => "Apache-2.0",
          :version     => "4.3.0",
          :url         => "https://github.com/choria-plugins/nrpe-agent",
          :timeout      => 30

requires :mcollective => "2.2.1"

dataquery :description => "Runs a Nrpe command and returns the exit code" do
  input   :query,
          :prompt       => "Command",
          :description  => "Valid Nrpe command",
          :type         => :string,
          :validation   => '\A[a-zA-Z0-9_-]+\z',
          :maxlength    => 20

  output  :exitcode,
          :description => "Exit code of Nrpe command",
          :display_as  => "Exit Code"
end
