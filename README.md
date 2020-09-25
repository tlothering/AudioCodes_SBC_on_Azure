# Deploy an AudioCodes Session Border Controller on Azure
Deployment repo for AudioCodes SBC Proof of Concept deployed on Microsoft Azure. These files are intended for testing and lab purposes only and are not ready to Production.

Refer to [Phone System and Direct Routing](https://docs.microsoft.com/en-us/MicrosoftTeams/direct-routing-landing-page) for detailed deployment information.

## v2.0

### Azure_Create_1_ACvSBC - Az.ps1

This PowerShell script will deploy a single AudioCodes Session Border Controller with all required networking for the 2x Interfaces on Azure. It deploys the SBC in a seperate Resource Group which is isolated which allows easy management and deprovision. It has several fields pre-populated for easy deployment and is recommeneded that this script be used to deploy Proof of Concept or testing environments only.

Edit this script to suit your needs and Azure region deployment as the default is **southafricanorth**, the editable fields are located in the **# Define Environment Variables** section.

**Script Requirements:**

Install the **AZ** PowerShell module before using this script;

*`Install-Module Az`*

> NOTE: Default password is **DirectRouting123!@#** and ***MUST BE CHANGED AS SOON AS POSSIBLE !!!***

### Azure AudioCodes VE SBC INI Configuration Files

This repo contains 2 .INI files:
- ***Standard Trunk for Single Tenant***: This INI can be used when you have a single Office 365 tenant.
- ***Derived Trunk for Carriers***: This INI can be used by Telecommunication Providers / Voice Carriers to manage 1000's of Office 365 SIP Trunks with a simple deployment.

The .INI files contain the basics for configuring the AudioCodes Session Border Controller for Microsoft Teams Direct Routing. Download the applicable .INI and edit the following changes:

- ***Standard Trunk Configuration:*** Replace ***SBC01.TEAMS.CONTOSO.COM*** with your registered Public DNS A Record for the Session Border Controller.
- ***Derived Trunk Configuration:*** Replace ***SBC01.TEAMS.CONTOSO.COM*** & ***SBC02.TEAMS.CONTOSO.COM*** with your registered Public DNS A Record for each Customer you are onboarding & replace ***TEAMS.CONTOSO.COM*** with your Carrier registered Public DNS A Record.

- Replace the ***DIALPLAN RULE*** section to align with your Numbering scheme

- Replace ***SIP.TRUNK.IP.HERE*** with the routable IP address of your SIP Trunk Provider

- Replace ***SBC.PSTN.IP.HERE*** with the external PSTN Public IP Address for the SBC

- Replace ***SBC.TEAMS.IP.HERE*** with the external TEAMS Public IP Address for the SBC

### Post Deployment Actions

- Import you Public SSL Certificate, Trusted Root & Intermediate Certification Authorities for your Certificate and the Baltimore Certificate
- Configure your PSTN SIP Trunk. A placeholder has been provided but will require additional configuration dependant on the settings provided by the SIP Trunk Provider.
- Configure the "NAT Translation" rules to the Public IP addresses assigned to the SBC.
- Configure Office 365 Tenant - [Connect your Session Border Controller (SBC) to Direct Routing](https://docs.microsoft.com/en-us/MicrosoftTeams/direct-routing-connect-the-sbc)
- Configure Voice Routing Policies and Dial Plans [Configure voice routing for Direct Routing](https://docs.microsoft.com/en-us/MicrosoftTeams/direct-routing-voice-routing)
- Enable a User for Teams Direct Routing - [Enable users for Direct Routing, voice, and voicemail](https://docs.microsoft.com/en-us/MicrosoftTeams/direct-routing-enable-users)
