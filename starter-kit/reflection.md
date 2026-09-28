# Reflection

## 1. Where were you tempted to take shortcuts?

The biggest temptation was working directly on the \`main\` branch instead of creating separate feature branches. For a small documentation project it would have been faster, but doing so would not demonstrate a proper DevOps workflow. Using \`develop\` and \`feature/starter-kit-files\` helped me follow a collaborative branching strategy and made the project easier to review through a pull request.

## 2. Which architectural decision required the most reasoning?

Choosing the cloud service model required the most careful reasoning. I compared Infrastructure as a Service (IaaS), Platform as a Service (PaaS), and Software as a Service (SaaS). Although IaaS provides greater control, it also requires managing virtual machines and operating systems. I selected PaaS because KijaniKiosk is an early-stage platform whose priority is rapid application development rather than infrastructure management. This decision balances simplicity, scalability, and reduced operational overhead.

## 3. If the KijaniKiosk platform grows significantly, what would you improve first?

The first improvement I would make is increasing the platform's reliability by introducing automatic load balancing and database replication across multiple availability zones. As the number of customers grows, traffic will become less predictable, and a single application instance could become a bottleneck. Adding redundant infrastructure would improve availability, reduce downtime during failures, and provide a stronger foundation for future scaling.
