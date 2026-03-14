# Software Architecture Template

Ready-to-use C4 diagrams for documenting software architecture.

## System Context Diagram

High-level view of your system and its environment.

```mermaid
C4Context
    accTitle: System Context Diagram
    accDescr: High-level view showing system users, the main system, and external service dependencies.
    title System Context Diagram - [TODO: Your System Name]

    %% TODO: Define your users/personas
    Person(user, "End User", "Primary user of the system")
    Person(admin, "Administrator", "Manages system configuration")

    %% TODO: Define your main system
    System(system, "Your System", "TODO: Brief description of what your system does")

    %% TODO: Define external systems
    System_Ext(email, "Email Service", "Sends transactional emails")
    System_Ext(payment, "Payment Gateway", "Processes payments")
    System_Ext(analytics, "Analytics Platform", "Tracks usage metrics")

    %% TODO: Define relationships
    Rel(user, system, "Uses")
    Rel(admin, system, "Manages")
    Rel(system, email, "Sends emails via")
    Rel(system, payment, "Processes payments through")
    Rel(system, analytics, "Reports metrics to")
```

## Example System Context

```mermaid
C4Context
    accTitle: Example System Context
    accDescr: Sample platform showing three user types, the main system, and external service integrations.
    title Example System Context

    Person(enduser, "End User", "Primary consumer of the platform")
    Person(provider, "Service Provider", "Delivers services on the platform")
    Person(manager, "Manager", "Assigns staff and manages operations")

    System(platform, "Platform", "Flutter app with offline-first sync")

    System_Ext(supabase, "Supabase", "Auth, Database, Storage, Edge Functions")
    System_Ext(powersync, "PowerSync", "Offline-first data sync")
    System_Ext(firebase, "Firebase", "Push notifications via FCM")
    System_Ext(sentry, "Sentry", "Error tracking and monitoring")

    Rel(enduser, platform, "Uses", "Consumer Portal")
    Rel(provider, platform, "Uses", "Provider Portal")
    Rel(manager, platform, "Uses", "Administration")
    Rel(platform, supabase, "Auth, data, files", "HTTPS")
    Rel(platform, powersync, "Real-time sync", "WebSocket")
    Rel(platform, firebase, "Push notifications", "HTTPS")
    Rel(platform, sentry, "Error reports", "HTTPS")
```

## Container Diagram

Zoom into your system to show the high-level technology decisions.

```mermaid
C4Container
    accTitle: Container Diagram
    accDescr: Internal containers showing frontend apps, backend services, data stores, and their relationships.
    title Container Diagram - [TODO: Your System Name]

    Person(user, "User", "End user")

    System_Boundary(system, "Your System") {
        %% Frontend containers
        Container(web, "Web Application", "React/Vue/Angular", "Single-page application")
        Container(mobile, "Mobile App", "Flutter/React Native", "Cross-platform mobile app")

        %% Backend containers
        Container(api, "API Gateway", "Node.js/Go/Python", "Handles all API requests")
        Container(auth, "Auth Service", "Node.js", "Handles authentication")
        Container(core, "Core Service", "Go/Java", "Core business logic")
        Container(worker, "Background Worker", "Python", "Async job processing")

        %% Data containers
        ContainerDb(db, "Database", "PostgreSQL", "Stores application data")
        ContainerDb(cache, "Cache", "Redis", "Session and data caching")
        ContainerQueue(queue, "Message Queue", "RabbitMQ/SQS", "Async communication")
    }

    %% External systems
    System_Ext(email, "Email Service", "SendGrid/AWS SES")
    System_Ext(storage, "File Storage", "AWS S3")

    Rel(user, web, "Uses", "HTTPS")
    Rel(user, mobile, "Uses", "HTTPS")
    Rel(web, api, "Calls", "JSON/HTTPS")
    Rel(mobile, api, "Calls", "JSON/HTTPS")
    Rel(api, auth, "Authenticates via", "gRPC")
    Rel(api, core, "Routes to", "gRPC")
    Rel(core, db, "Reads/Writes", "SQL")
    Rel(core, cache, "Caches in", "Redis Protocol")
    Rel(core, queue, "Publishes to", "AMQP")
    Rel(worker, queue, "Consumes from", "AMQP")
    Rel(worker, email, "Sends via", "HTTPS")
    Rel(core, storage, "Stores files in", "HTTPS")
```

## Component Diagram

Zoom into a specific container to show its internal structure.

```mermaid
C4Component
    accTitle: API Gateway Component Diagram
    accDescr: Internal structure of the API Gateway showing controllers, services, validators, and middleware.
    title Component Diagram - API Gateway

    Container_Boundary(api, "API Gateway") {
        %% Controllers/Handlers
        Component(authCtrl, "Auth Controller", "Express Router", "Login, logout, token refresh")
        Component(userCtrl, "User Controller", "Express Router", "User CRUD operations")
        Component(orderCtrl, "Order Controller", "Express Router", "Order management")

        %% Services
        Component(authSvc, "Auth Service", "Node.js", "Authentication logic")
        Component(userSvc, "User Service", "Node.js", "User business logic")
        Component(orderSvc, "Order Service", "Node.js", "Order business logic")

        %% Infrastructure
        Component(validator, "Validator", "Joi/Zod", "Request validation")
        Component(middleware, "Middleware", "Express", "Auth, logging, errors")
    }

    %% External dependencies
    ContainerDb(db, "Database", "PostgreSQL")
    Container(cache, "Cache", "Redis")

    Rel(authCtrl, authSvc, "Uses")
    Rel(userCtrl, userSvc, "Uses")
    Rel(orderCtrl, orderSvc, "Uses")
    Rel(authCtrl, validator, "Validates with")
    Rel(userCtrl, validator, "Validates with")
    Rel(authSvc, db, "Reads/Writes")
    Rel(userSvc, db, "Reads/Writes")
    Rel(orderSvc, db, "Reads/Writes")
    Rel(authSvc, cache, "Caches tokens")
```

## Usage Instructions

1. Copy the relevant diagram template above
2. Replace all `TODO:` comments with your actual system details
3. Adjust container names, technologies, and relationships
4. Remove unused components
5. Include `accTitle` and `accDescr` for accessibility
6. Test in [Mermaid Live Editor](https://mermaid.live/)

## C4 Element Reference

| Element | Syntax | Use |
|---------|--------|-----|
| Person | `Person(id, "Name", "Desc")` | Users/actors |
| System | `System(id, "Name", "Desc")` | Your system |
| External | `System_Ext(id, "Name", "Desc")` | External systems |
| Container | `Container(id, "Name", "Tech", "Desc")` | Applications |
| Database | `ContainerDb(id, "Name", "Tech", "Desc")` | Data stores |
| Queue | `ContainerQueue(id, "Name", "Tech", "Desc")` | Message queues |
| Component | `Component(id, "Name", "Tech", "Desc")` | Code modules |
| Boundary | `System_Boundary(id, "Name") { }` | System grouping |
| Relationship | `Rel(from, to, "Label", "Tech")` | Connections |

## Customization Tips

- C4 diagrams do NOT support theme init blocks — they use built-in C4 styling
- Use `System_Boundary()` for grouping related containers
- Use `Container_Boundary()` for grouping components within a container
- Add technology labels to relationships for protocol clarity
- Keep descriptions concise — they render as subtitle text
