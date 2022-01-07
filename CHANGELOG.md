# Changelog

Change history for `choria/mcollective_agent_nrpe`

## 4.2.0

Released 2022-01-07

 * Increase nrpe check timeout to 30 seconds

## 4.1.0

Released 2019-01-23

 * Allow NRPE commands to be run as a specific user

## 4.0.1

Released 2018-04-20

 * Include JSON DDL files
 * Add Licencing files and contribution guidelines

## 4.0.0

 * Initial release as part of the Choria Project

## 3.1.0

 * Fully qualified call to ::MCollective::Shell to avoid clash with Shell agent
   (MCOP-425)
 * Add "runallcommand" action to the agent (PR#5, PR#14)
 * Add "args" parameter to the "runcommand" action (PR#15)

## 3.0.3

Released 2014-06-18

 * Added pl:packaging to support {yum,apt}.puppetlabs.com (MCOP-74)
