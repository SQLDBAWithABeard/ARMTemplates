# using this template

So to install the machines

clone the repository to your own github - make it public

Alter the parameters.json files

## Alter parameter values

DomainController.parameters.json - DNSPrefix - needs to be unique - small letters - less than 24 (?)

OctopusDeploy.parameters.json - networkDnsName -needs to be unique - small letters - less than 24 (?)

Thats all that needs to be changed - If you change some other values (like Domain Controller name) you will need to alter the references in other parameter files

Commit and push changes to GitHub - in as a step as I forgot this a couple of times and wondered why my changes did not deploy

Run the deploy.ps1 script - you will need to uncomment the login-azurermaccount if not logged in already

It takes just over an hour to run

