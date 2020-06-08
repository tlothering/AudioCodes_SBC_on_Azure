# Deploy an AudioCodes Session Border Controller on Azure
Deployment repo for AudioCodes SBC deployed on Microsoft Azure

Refer to [Phone System and Direct Routing](https://docs.microsoft.com/en-us/MicrosoftTeams/direct-routing-landing-page) for detailed deployment information

## v1.0

### Azure_Create_1_ACvSBC - Az.ps1

This PowerShell script will deploy a single AudioCodes Session Border Controller with all required networking for the 2x Interfaces on Azure. It has several fields pre-populated for easy deployment and is recommeneded that this script be used to deploy Proof of Concept or testing environments only.

Edit this script to suit your needs and Azure region deployment as the default is **southafricanorth**

**Requirements:**

Install the **AZ** PowerShell module before using this script;

`Install-Module Az`

> NOTE: Default password is **DirectRouting123!@#** and MUST BE CHANGED AS SOON AS POSSIBLE !!!

### Azure_AudioCodes_VE_SBC_Default_Config.ini

This repo contains 2 .INI files
- Standard Trunk: This INI can be used when you have a single Office 365 tenant or if you want to dedicate a SIP Port to every Office 365 tenant when deploying in a Multi-Tenant scenario
- Derived Trunk: This INI is can be used by Telecommunication Providers / Voice Carriers to managed 1000's of Office 365 SIP Trunks with a simple deployment.

The .INI files contain the basics for configuring the AudioCodes Session Border Controller for Microsoft Teams Direct Routing. Download the .INI and edit the following changes:

- Replace **SBC01.TEAMS.CONTOSO.COM** & **SBC02.TEAMS.CONTOSO.COM** with your registered Public DNS A Record

- Row 213: Replace **SIP.TRUNK.IP.HERE** with the routable IP address of your SIP Trunk Provider

- Row 277: Replace the **SBC.PSTN.IP.HERE** with the Public facing Internet IP Address for the PSTN network provided at the end of the PowerShell script

- Row 278: Replace the **SBC.TEAMS.IP.HERE** with the Public facing Internet IP Address for the TEAMS network provided at the end of the PowerShell script

### Post Deployment Actions

- Import Public SSL Certificate, Trusted Root & Intermediate Certification Authorities
- Configure Office 365 Tenant
- Configure Routing Policies and Dial Plans
- Enable a User for Teams Direct Routing
