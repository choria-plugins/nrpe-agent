# Choria NRPE Agent

This agent is capable of calling NRPE plugins on demand.

## Background

Often after just doing a change on servers you want to just be sure that they’re all going to pass a certain nagios check.

Say you’ve deployed some new code and restarted tomcat, there might be a time while you will experience high loads, you can very quickly determine when all your machines are back to normal using this. It can take nagios many minutes to check all your machines which is a totally unneeded delay in your deployment process.

If you put your nagios checks on your servers using the common Nagios NRPE then this agent can be used to quickly check it across your entire estate.

I wrote a blog post on using this plugin to aggregate checks for Nagios: [Aggregating Nagios Checks With MCollective](http://www.devco.net/archives/2010/07/03/aggregating_nagios_checks_with_mcollective.php)

## Setting up NRPE

This agent makes an assumption or two about how you set up NRPE, in your nrpe.cfg add the following:

```
include_dir=/etc/nagios/nrpe.d/
```

You should now set your commands up one file per check command, for example /etc/nagios/nrpe.d/check_load.cfg:

```
command[check_load]=/usr/lib64/nagios/plugins/check_load -w 1.5,1.5,1.5 -c 2,2,2
```

With this setup the agent will now be able to find your `check_load` command.

<!--- actions -->

## Agent Installation

Add the agent and client:

```yaml
mcollective::plugin_classes:
  - mcollective_agent_nrpe
```

## Configuration
You can set the directory where the NRPE cfg files live, it defaults to `/etc/nagios/nrpe.d`:

```yaml
mcollective_agent_nrpe::config:
 conf_dir: /usr/localetc/nagios/nrpe.d
```

Alternatively if you have just one file with many plugins defined you can configure its location as below, this is is mutually exclusive with the previous settings:

```yaml
mcollective_agent_nrpe::config:
 conf_file: /usr/localetc/nagios/nrpe.cfg
```

And finally you can specify multiple directories as below:

```yaml
mcollective_agent_nrpe::config:
 conf_path: /usr/localetc/nagios/nrpe.d:/other/nrpe.d
```

## Usage

### Using generic mco rpc

You can use the normal mco rpc script to run the agent:

```
% mco rpc nrpe runcommand command=check_load
Discovering hosts using the mongo method .... 27

 * [ ============================================================> ] 27 / 27


dev1.example.com                             Request Aborted
   UNKNOWN
          Exit Code: 3
             Output: No such command: check_load
   Performance Data:


Summary of Exit Code:

           OK : 26
      UNKNOWN : 1
      WARNING : 0
     CRITICAL : 0


Finished processing 27 / 27 hosts in 380.57 ms
```

### Supplied Client
Or we provide a client specifically for this agent that is a bit more appropriate for the purpose:

The client by default only shows problems:

```
% mco nrpe -W /dev_server/ check_load

 * [ ============================================================> ] 19 / 19

dev1.example.com                           status=UNKNOWN
    No such command: check_load

Summary of Exit Code:

           OK : 18
      UNKNOWN : 1
      WARNING : 0
     CRITICAL : 0


Finished processing 19 / 19 hosts in 216.59 ms
```

To see all the statusses:

```
% mco nrpe -W /dev_server/ check_load -v
Discovering hosts using the mongo method .... 3

 * [ ============================================================> ] 6 / 6

dev1.example.com                           status=UNKNOWN
    No such command: check_load

dev9.example.com                           status=OK
    OK - load average: 0.00, 0.00, 0.00

dev7.example.com                           status=OK
    OK - load average: 0.00, 0.00, 0.00

Summary of Exit Code:

           OK : 2
      UNKNOWN : 1
     CRITICAL : 0
      WARNING : 0


---- check_load NRPE results ----
           Nodes: 3 / 3
     Pass / Fail: 2 / 1
      Start Time: Fri Dec 14 11:21:58 +0000 2012
  Discovery Time: 50.86ms
      Agent Time: 212.90ms
      Total Time: 263.76ms
```

### Data Plugin

The NRPE Agent ships with a data plugin that will enable you to filter discovery on the results of NRPE commands.

```
%  mco rpc rpcutil ping -S "Nrpe('check_disk1').exitcode=0"
Discovering hosts using the mc method for 3 second(s) .... 1

 * [ ============================================================> ] 1 / 1


dev2.example.com
   Timestamp: 1355484245


Finished processing 1 / 1 hosts in 138.15 ms
```
