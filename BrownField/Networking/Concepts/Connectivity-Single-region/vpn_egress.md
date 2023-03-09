---
title: Manage traffic natively from Azure VMWare Solution with NSX-T or NVA
description: Direct egress and ingress traffic from Azure VMware Solution
author: sablair, magodfre, deanmiller, jasonmedina, robinher, khushkaviraj
ms.author: martinek
ms.date: 02/14/2023
ms.topic: conceptual
ms.service: cloud-adoption-framework
ms.subservice: scenario
ms.custom: e2e-azure-vmware, think-tank
---

# Enable connectively from Azure VMware Solution using NSX-T or NVA (network virtual appliances)
## Introduction
In this design pattern, traffic has a dedicated path over the Microsoft backbone from the on-premises datacenter to the Azure VMware Solution (AVS) private cloud via the Expressroute Global Reach, a mechanism that supplies a direct path between the customer managed and the AVS dedicated Expressroute circuits. The private cloud also has a separate, isolated breakout from the NSX Edge to the internet so that this traffic does not traverse over the Expressroute.  

[![Azure VMware Solution with Global Reach to On-premises and separate breakout for the internet with AVS Public IP](./media/publicip.png)](./media/publicip.png)

Important: If you’re in a region today where Global Reach is not supported, transit from on-premises to the AVS private cloud is possible by connecting to the Expressroute Gateway Azure. To supply the transitivity end-to-end, a virtual appliance in the Hub Virtual Network (VNET) is needed. Please see the section Traffic Inspection & Default Route Advertisement below. 

### Customer profile

This architecture is ideal for:
•	Low latent, egress natively from the Azure VMware Solution SDDC (software-defined datacenters) to the internet.
•	Direct traffic from on-premises directly to Azure via Expressroute or VPN.
•	Inbound L4/L7 services for workloads in the SDDC such as HTTPS
 


The traffic, which flows through the AVS NSX routers, covered in this design include:

•	Azure VMware Solution to Azure native virtual networks
•	Azure VMware Solution to the internet 
•	Azure VMware Solution to on-premises datacenters 
 





### Architectural components

Implement this scenario with:

•	An NSX Distributed Firewall (DFW) – version 3.2.2 or higher
•	An NSX Advanced Load balancer 
•	Public IP for Internet breakout from Azure VMware Solution for both source and destination address translation (SNAT/DNAT)

Note: While NSX load balancer (Avi) is recommended as the lowest latent choice, HTTPS is also possible with WAF/App Gateway v2 in Azure.

#### Key Decision

This document assumes and recommends default route advertisement from either on-premises or AVS. If you need the default route to originate from Azure, please see the section below

 
### Considerations 

•	Enable Public IP down to the NSX Edge in Azure Portal. This way allows for low-latency direct connections to Azure VMware Solution, and the ability to scale the number of outbound connections.
•	Leverage the NSX firewall for granular rule creation, URL filtering, and TLS Inspection.
•	Consider using AVI load balancer to evenly distribute traffic to workloads.
•	Enable DDoS protection.

#### Egress from AVS using NSX-T or NVA 

| Traffic inspection coverage | Recommended solution design | Considerations | Internet Breakout |
|----|---|---|---|
| - Internet ingress <br> - Internet egress <br> - Traffic to and on-premises datacenter <br> - Traffic to Azure Virtual Network <br> - Traffic within Azure VMware Solution <br>|   Use NSX-T or a third-party NVA firewall in Azure VMware Solution. </br></br>  Use NSX-T Advanced Load Balancer for HTTPs, or NSX-T Firewall for non-HTTPs traffic. </br></br> Public IP for Internet breakout from Azure VMware Solution, SNAT, and DNAT. | Enable Public IP down to the NSX Edge in Azure Portal. This option allows for low-latency connections to Azure, and the ability to scale the number of outbound connections. </br></br> Leverage the NSX firewall for granular rule creation, URL filtering, and TLS Inspection. </br></br> Consider using a load balancer to evenly distribute traffic to workloads. </br></br> Enable DDoS protection.  | Azure VMWare Solution

####  Egress from Azure VMware Solution through 0.0.0.0/0 advertisement from on-premises
| Traffic inspection coverage | Recommended solution design | Considerations | Internet Breakout |
|----|---|---|---|
| - Internet ingress <br> - Internet egress <br> - To on-premises datacenter| Use Virtual WAN secured hub. </br></br>  For HTTP/S traffic, use Azure Application Gateway. For non-HTTP/S traffic, use Azure Firewall.</br></br> Deploy a secured Virtual WAN hub and enable public IP in Azure VMware Solution. | Choose this option to advertise the `0.0.0.0/0` route from on-premises datacenters. | On-Premise

Important: Some traditional VMware appliances use service insertion to place appliances at the tier-0 router. The tier-0 routers are provisioned and managed by Microsoft and not consumable by end users. All network appliances and load balancers must be placed at tier-1. The next section discusses default route propagation from a party device in AVS. 
 
### Third Party NVA integration in AVS 
Integration with 3rd Party appliances is possible with careful consideration. In this design, NVA(s) sit behind one or more T-1 edge routers. 
 
The NVA is BYOL (Bring Your Own License). It is the consumers’ responsibility to bring a license and implement high availability for the NVA.
 
For NVA placement options and for information about the VMware limitation of up to eight virtual network interface cards (NICs) on a virtual machine see: https://github.com/Azure/Enterprise-Scale-for-AVS/tree/main/networking/nsx-firewall-patterns

Note: Microsoft does not support the use of Mobility Optimized Networking when 3rd party NVAs are used.

## Landing Zone considerations
This section references best practices for integrating AVS with your Azure Landing Zone. 
### Azure Route Server
Azure route server (ARS) is used to dynamically propagate learned routes from AVS and supply Branch-to-Branch connectivity to VPN Gateways. VNET’s that are peered to the VNET where ARS lives will also dynamically learn routes. Use cases for Azure route server include:

o	Dynamic route propagation – 
o	Learn specific routes from AVS to local VNET’s via BGP (Border Gateway Protocol). Peered VNET’s will also learn the routes.
o	Third Party NVA integration- Peer ARS with NVA’s so that you don’t need UDR’s for each AVS segment to filter traffic.
o	Return traffic from peered VNET’s will need a UDR (User Defined Routes) back to the local interface of the firewall 
o	Transit mechanism from Expressroute to VPN Gateways
o	VPN Gateway must be of type Site-to-Site and configured in Active-Active 
To use Azure Route Server, please note the following:
o	Enable Branch to Branch
o	Route summarization for > 1000 routes or use NO_ADVERTISE BGP communities' flag Azure Route Server frequently asked questions (FAQs) | Microsoft Learn
o	Peering with NVA requires specific ASN’s. For example, since ARS uses 65515, no other appliance in the VNET can use that ASN (Autonomous System Number). 
o	No support for IPV6

## Inegration with Azure Netapp Files 
Azure Netapp Files (ANF) provides you with a Network Attached datastore. ANF lives in an Azure VNET and connects to workloads in AVS. 
•	Must use ANF standard SKU
•	Deploy ANF in a delegated subnet 
•	Hub & Spoke deployment supports ER GW SKU of up 10Gbps
•	Bypassing the gateway port speed limits is possible by using FastPath for Ultra & ___SKUs
•	If you’re seeing unexpected latency, make sure your AVS Private cloud and ANF deployment are pinned to the same AZ (Azure Availability Zones). This is in preview via CLI but can also be obtained by opening a support ticket. 
•	Read traffic will ingress and write traffic is egress over the Expressroute. Egress traffic over Expressroute circuits will bypass the gateway and go directly to the edge router 
•	For high availability, create an ANF volumes in separate AZ’s and enable `Cross Zone Replication`
•	Ingress/Egress charges are suppressed from AVS, however there is an egress charge if data is going across peered VNET’s. 
•	Only NFS v3 is supported today. 


### VPN connectivity from On-Premises

While an Expressroute circuit is recommended, connecting to AVS from on-premises with IPSEC using a transit hub VNET in Azure is also possible. This will require a VPN gateway and Azure Route Server. As referenced earlier, Azure Route Server will enable transitivity between the VPN gateway and the AVS Expressroute gateway.

[![Azure VMware Solution with transit between Expressroute and On-premises VPN Gateway](./media/publicip.png)](./media/vpn_to_er.png)

## Traffic Inspection 
As seen earlier, default route advertisement is happening from AVS with the Public IP down to the NSX Edge option, but it is also possible to continue advertising the default route from on-premises. End-to-end traffic filtering from on-premises to AVS is possible with the firewall placed at either of these endpoints. 

If you need to advertise a default route from both on-premises and AVS, please consider…[TBD]

Default route advertisement from Azure is possible with 3rd party NVA or when using Azure vWAN. In a Hub & Spoke deployment, Azure Firewall is not possible because it does not speak BGP, however use of a third party BGP capable device works. This scenario works for inspecting traffic from 
o	On premises to Azure
o	Azure to the internet
o	AVS to the internet 
o	AVS to Azure


## Additional Information 

o	Access vCenter using Bastion + Jumpbox VM. If you are accessing vCenter from on-premises, please be sure to…. Have a route from your on-premises networks to the /22 AVS management network that is not blocked by a firewall or routing policies.  Test using Test-NetConnection  x.x.x.2 -port 443
o	DNS considerations:  If using private endpoints follow the guidance detailed here: Azure Private Endpoint DNS configuration | Microsoft Learn

[![Azure VMware Solution with transit between Expressroute and On-premises VPN Gateway](./media/publicip.png)](./media/alz_avs.png)
## Next steps

- For more information on how to transit from On-premises VPN to Azure VMWare Solution, see the following [VPN to ExR transit how to article:](https://github.com/Azure/Enterprise-Scale-for-AVS/tree/main/BrownField/Networking/Step-By-Step-Guides/Hub%20VNET%20with%20VPN%20to%20ExpressRoute%20Gateway%20transit)
- For more information about Azure VMware Solution in hub-and-spoke networks, see [Integrate Azure VMware Solution in a hub and spoke architecture](/azure/azure-vmware/concepts-hub-and-spoke).
- For more information on VMware NSX-T Data Center network segments, see [Configure NSX-T Data Center network components using Azure VMware Solution](/azure/azure-vmware/configure-nsx-network-components-azure-portal#create-an-nsx-t-segment-in-the-azure-portal).
- To learn Cloud Adoption Framework enterprise-scale landing zone architectural principles, various design considerations, and best practices for Azure VMware Solution, see the next article in this series:

Next, observe additional design patterns for establishing connectivity to the Azure VMware Solution

  > [!div class="nextstepaction"]
  > [Example Architectures for Azure VMware Solution](./egress-from-avs.md)
