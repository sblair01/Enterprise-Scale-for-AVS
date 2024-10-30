## Overview

Deploying Azure VMware Solution (AVS) with high availability is crucial for minimizing downtime, ensuring critical application operation and data integrity. High availability supports:

&nbsp;

  1\. 99.99% uptime (SLA compliance)

  2\. Redundancy and failover capabilities

  3\. Data replication and protection

  4\. Low-latency replication and high-speed connectivity

&nbsp;

Operational continuity and meeting technical/business requirements depend on high availability design. This article will discuss how to design an AVS Private Cloud with High Availability.  

## Workload Considerations

Using the Azure VMware Solution across multiple Availability Zones (AZs) allows for:

- **High Availability**: Ensuring that applications and services remain available even if one AZ experiences an outage. This is crucial for critical applications that require minimal downtime.  
- **Disaster Recovery**: By replicating data and services across multiple AZs, customers can quickly recover from natural disasters or other catastrophic events that might affect a single availability zone
  - **Important** -Multi-AZ deployment will not suffice in a regional disaster. In such a regional event, also deploy AVS across a secondary region.  
- **Low Latency Requirements**: Some applications require very low latency for data replication. Deploying across multiple AZs within the same region can meet these stringent latency requirements.  
- **Cost Management**: Customers can optimize costs by deploying different numbers of resources in each AZ based on their specific needs and SLAs, rather than duplicating entire setups.  

In disaster recovery (DR) scenarios, deploying across multiple regions may present latency challenges that are not as prevalent when staying within a single region. This is particularly important for applications and third-party replication tools that require round-trip replication times of 2ms or less.  

### Tools

When utilizing a two-availability zone deployment, you can replicate your virtual machines using [VMware Site Recovery](https://learn.microsoft.com/en-us/azure/azure-vmware/disaster-recovery-using-vmware-site-recovery-manager). In this scenario, you designate a primary datacentre to host all virtual machines and replicate to the secondary data center . This can achieve near-zero downtime recovery.  Servers with an SLA of 99.9% do not require replication and are covered by the single AZ Azure VMware SLA. For more information on Azure VMware SLAs, please consult the Service Level Agreements for Microsoft Online Services available  [here](https://www.microsoft.com/licensing/docs/view/Service-Level-Agreements-SLA-for-Online-Services?lang=1).  

Note: There are 3<sup>rd</sup> party tools that can handle replicating data across zones. A list of 3<sup>rd</sup> party supported tools can be found [here](https://learn.microsoft.com/en-us/azure/azure-vmware/ecosystem-disaster-recovery-vms)

### Availability Zone Placement

To place an SDDC in a specific availability zone within a region, a service request must be raised to specify the desired availability zone (e.g., AZ1,AZ2)

It is important to ensure that the subscriptions are mapped correctly to the physical data centers corresponding to the requested availability zones.  

This process helps in confirming that the SDDCs are physically separated into different availability zones, providing the necessary redundancy and high availability.  

## Network Resiliency

Network redundancy is a crucial element for any Azure VMware solution design, you have two options:

1. ExpressRoute connectivity  

or

1. VPN Connectivity  

In this article we are going to focus on ExpressRoute connectivity.  

### ExpressRoute

&nbsp;

The ExpressRoute, when provisioned comes with a redundant pair of cross connections that are configured for high availability. While this configuration has redundancy built in, it does not provide you full path redundancy. Full path redundancy refers to having multiple, independent network paths to ensure continuous connectivity even if one path fails. This involves using multiple ExpressRoute circuits or other network connections to provide alternative routes for data traffic, enhancing reliability and fault tolerance.  

To enable full ExpressRoute redundancy, it is recommended that two express routes in two physical peering locations are configured and connected into Azure. The express route gateways, Azure Firewalls can be configured in an active/active state to give the networking a fully redundant configuration that can withstand a peering location failure. A diagram of a multi–AZ Azure VMware solution with fully redundant networking configuration can be seen below:

![A screenshot of a computer

Description automatically generated]

In the example above both ExpressRoute circuits are connected to one physical datacentre each in a separate physical location.

If you have two separate on-premises datacenters, one ExpressRoute would connect to the secondary datacenter via a third-party provider. This setup allows traffic from the primary datacenter to flow through the secondary datacenter into Azure during a primary connection disaster. Below is a high-level overview of the design:

&nbsp;

![A screenshot of a computer

Description automatically generated]

Enabling [FastPath](https://learn.microsoft.com/en-us/azure/expressroute/about-fastpath) for ExpressRoute gateways improves data path performance by sending network traffic directly to virtual machines in the virtual network, bypassing the ExpressRoute gateway, which reduces the number of hops and potential bottlenecks. The SKUs that support FastPath are Ultra Performance and ErGw3AZ.

AVS Interconnect

The Interconnect is used to create a high-speed link between the SDDCs deployed in different availability zones within the same region.

This high-speed link is crucial for meeting the low-latency requirements of certain critical applications, ensuring that the latency remains within acceptable limits (e.g., 2-3 milliseconds)

The interconnect helps in achieving the necessary performance for storage replication and application-level replication between the SDDCs

[Connect multiple Azure VMware Solution private clouds in the same region - Azure VMware Solution | Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-vmware/connect-multiple-private-clouds-same-region)

Benefits of Decoupled Private Cloud Architecture

While stretched clusters are the primary way to stretch VSAN storage across zones, there are some advantages to deploying two separate private clouds altogether across zones.

- **Flexibility in Resource Allocation**: This approach permits an uneven distribution of resources, allowing for the allocation of more hosts to one zone and fewer to another based on specific requirements. This flexibility is not feasible with stretched clusters, which require duplication of all resources across zones. Certain applications, such as development/testing or those with lower SLAs, may not necessitate residing in both zones, thereby eliminating the need for redundant hosts.  
- **Tailored Disaster Recovery**: This strategy allows for customized disaster recovery plans, enabling organizations to replicate only critical applications to the secondary zone, thus optimizing resource utilization.
- **Simplified Management**: Managing separate clusters can be less complex and more straightforward than managing stretched clusters, which demand synchronized operations across multiple zones.

&nbsp;

## Conclusion

Decoupling a private cloud across availability offers flexibility in resource allocation allowing organizations to customize their infrastructure to optimize resource consumption, while achieving robust disaster recovery capabilities.

Next, we will discuss how to chaos this implementation (Coming Soon)



Additional Links:
