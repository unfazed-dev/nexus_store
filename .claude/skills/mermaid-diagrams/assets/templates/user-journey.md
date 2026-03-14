# User Journey Template

Ready-to-use journey diagrams for documenting user experiences and satisfaction scoring.

## Customer Service Request Journey

```mermaid
journey
    title Customer Service Request Journey
    section Discovery
        Browse available services: 4: Customer
        View service details: 4: Customer
        Check pricing: 3: Customer
    section Request
        Submit service request: 5: Customer
        Select preferred times: 4: Customer
        Add special requirements: 3: Customer
    section Assignment
        Review request details: 4: CLM
        Match contractor skills: 4: CLM
        Assign staff: 5: CLM
        Notify customer: 5: CLM, Customer
    section Service Delivery
        Confirm booking: 5: Customer
        Receive service: 4: Customer, Contractor
        Complete service notes: 3: Contractor
    section Billing
        Review invoice: 3: Customer
        Pay via Kinly Wallet: 4: Customer
        Receive payment confirmation: 5: Customer
```

## Contractor Onboarding Journey

```mermaid
journey
    title Contractor Onboarding Journey
    section Application
        Submit application: 4: Contractor
        Upload credentials: 3: Contractor
        Complete background check: 2: Contractor
    section Verification
        Review application: 4: Admin
        Verify credentials: 3: Admin
        Approve contractor: 5: Admin
    section Setup
        Accept terms: 3: Contractor
        Set availability: 4: Contractor
        Define service areas: 4: Contractor
        Upload profile photo: 3: Contractor
    section First Assignment
        Receive first booking: 5: Contractor
        Complete service: 4: Contractor
        Get first review: 5: Contractor, Customer
```

## CLM Daily Workflow Journey

```mermaid
journey
    title Care Liaison Manager Daily Workflow
    section Morning Review
        Check new requests: 4: CLM
        Review pending assignments: 3: CLM
        Check contractor availability: 3: CLM
    section Assignment Work
        Match requests to contractors: 4: CLM
        Handle scheduling conflicts: 2: CLM
        Confirm assignments: 5: CLM
        Notify all parties: 4: CLM
    section Monitoring
        Track in-progress bookings: 4: CLM
        Handle escalations: 2: CLM
        Review completed services: 4: CLM
    section End of Day
        Process pending invoices: 3: CLM
        Update reports: 3: CLM
        Plan next day: 4: CLM
```

## Multi-Portal Feature Access Journey

```mermaid
journey
    title Feature Access Across Portals
    section Customer Portal
        View bookings: 5: Customer
        Request new service: 4: Customer
        Track booking status: 4: Customer
        Pay invoices: 3: Customer
    section Services Hub
        View assignments: 5: Contractor
        Update availability: 4: Contractor
        Complete timesheets: 3: Contractor
        View earnings: 4: Contractor
    section Administration
        Manage users: 4: Admin
        Review compliance: 3: Admin
        Generate reports: 3: Admin
        Configure services: 4: Admin
```

## Usage Instructions

1. Copy the relevant journey template
2. Update the title to describe the journey
3. Modify sections to match your user flow stages
4. Update tasks with appropriate satisfaction scores (1-5)
5. Assign actors to each task
6. Test in [Mermaid Live Editor](https://mermaid.live/)

## Journey Syntax Reference

| Feature | Syntax | Example |
|---------|--------|---------|
| Title | `title Text` | `title Customer Journey` |
| Section | `section Name` | `section Onboarding` |
| Task | `Task name: score: actors` | `Sign up: 5: Customer` |
| Multiple actors | `Task: score: A, B` | `Meet: 4: CLM, Customer` |

## Satisfaction Scoring Guide

| Score | Meaning | Use When |
|-------|---------|----------|
| 1 | Very frustrated | Pain point, major blocker |
| 2 | Frustrated | Difficult step, high friction |
| 3 | Neutral | Acceptable but not great |
| 4 | Satisfied | Good experience, minor friction |
| 5 | Delighted | Excellent, seamless experience |

## Tips

- Journey diagrams do NOT support theme init blocks or classDef styling
- Focus on emotional experience, not technical steps
- Use scores to highlight pain points (1-2) that need improvement
- Group related steps into meaningful sections
- Include all relevant actors for each step
- Keep task names short (they render as labels on the chart)
