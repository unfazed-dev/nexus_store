# API Flow Template

Ready-to-use sequence diagrams for documenting API interactions.

## REST API Flow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
sequenceDiagram
    accTitle: REST API Authentication and Request Flow
    accDescr: Full auth login flow followed by an authenticated resource request with caching.
    autonumber
    participant Client
    participant API as API Gateway
    participant Auth as Auth Service
    participant Service as Business Service
    participant DB as Database
    participant Cache as Cache

    %% TODO: Customize this flow for your API

    Note over Client,Cache: Authentication Flow
    Client->>+API: POST /auth/login {email, password}
    API->>+Auth: Validate credentials
    Auth->>+DB: SELECT user WHERE email = ?
    DB-->>-Auth: User record
    Auth->>Auth: Verify password hash
    Auth->>+Cache: Store session
    Cache-->>-Auth: OK
    Auth-->>-API: JWT token
    API-->>-Client: 200 OK {token, refreshToken}

    Note over Client,Cache: Authenticated Request
    Client->>+API: GET /api/resource<br/>Authorization: Bearer {token}
    API->>+Auth: Validate token
    Auth->>+Cache: Check token validity
    Cache-->>-Auth: Valid
    Auth-->>-API: User context
    API->>+Service: Get resource for user
    Service->>+DB: SELECT * FROM resources WHERE user_id = ?
    DB-->>-Service: Resource data
    Service-->>-API: Resource DTO
    API-->>-Client: 200 OK {data}
```

## CRUD Operations

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
sequenceDiagram
    accTitle: CRUD Operations Flow
    accDescr: Standard Create, Read, Update, Delete operations through API, service, and database layers.
    participant Client
    participant API
    participant Service
    participant DB

    Note over Client,DB: CREATE
    Client->>+API: POST /items {name, data}
    API->>API: Validate request
    API->>+Service: Create item
    Service->>+DB: INSERT INTO items
    DB-->>-Service: New item ID
    Service-->>-API: Created item
    API-->>-Client: 201 Created {item}

    Note over Client,DB: READ
    Client->>+API: GET /items/{id}
    API->>+Service: Get item
    Service->>+DB: SELECT * FROM items WHERE id = ?
    DB-->>-Service: Item data
    Service-->>-API: Item DTO
    API-->>-Client: 200 OK {item}

    Note over Client,DB: UPDATE
    Client->>+API: PUT /items/{id} {updates}
    API->>API: Validate request
    API->>+Service: Update item
    Service->>+DB: UPDATE items SET ... WHERE id = ?
    DB-->>-Service: Updated rows
    Service-->>-API: Updated item
    API-->>-Client: 200 OK {item}

    Note over Client,DB: DELETE
    Client->>+API: DELETE /items/{id}
    API->>+Service: Delete item
    Service->>+DB: DELETE FROM items WHERE id = ?
    DB-->>-Service: Deleted rows
    Service-->>-API: Success
    API-->>-Client: 204 No Content
```

## Error Handling

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
sequenceDiagram
    accTitle: API Error Handling Patterns
    accDescr: Standard error responses for validation, not found, unauthorized, and server errors.
    participant Client
    participant API
    participant Service
    participant DB

    Note over Client,DB: Validation Error
    Client->>+API: POST /items {invalid data}
    API->>API: Validate request
    API-->>-Client: 400 Bad Request {errors: [...]}

    Note over Client,DB: Not Found
    Client->>+API: GET /items/unknown-id
    API->>+Service: Get item
    Service->>+DB: SELECT * FROM items WHERE id = ?
    DB-->>-Service: Empty result
    Service-->>-API: NotFoundError
    API-->>-Client: 404 Not Found {message}

    Note over Client,DB: Unauthorized
    Client->>+API: GET /protected (no token)
    API->>API: Check authorization
    API-->>-Client: 401 Unauthorized

    Note over Client,DB: Server Error
    Client->>+API: POST /items {data}
    API->>+Service: Create item
    Service->>+DB: INSERT INTO items
    DB-->>-Service: Connection error
    Service-->>-API: DatabaseError
    API-->>-Client: 500 Internal Server Error
```

## Async Processing

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
sequenceDiagram
    accTitle: Async Job Processing Flow
    accDescr: Job submission via API, background worker processing via message queue, and status polling.
    participant Client
    participant API
    participant Queue as Message Queue
    participant Worker
    participant DB
    participant Notify as Notification Service

    Note over Client,Notify: Submit Job
    Client->>+API: POST /jobs {payload}
    API->>API: Validate request
    API->>+DB: INSERT job (status: pending)
    DB-->>-API: Job ID
    API->>+Queue: Publish job message
    Queue-->>-API: Acknowledged
    API-->>-Client: 202 Accepted {jobId, statusUrl}

    Note over Client,Notify: Background Processing
    Queue->>+Worker: Deliver job message
    Worker->>+DB: UPDATE job SET status = 'processing'
    DB-->>-Worker: OK
    Worker->>Worker: Process job...
    Worker->>+DB: UPDATE job SET status = 'completed', result = ?
    DB-->>-Worker: OK
    Worker->>+Notify: Send completion notification
    Notify-->>-Worker: Sent
    Worker-->>-Queue: Acknowledge

    Note over Client,Notify: Check Status
    Client->>+API: GET /jobs/{id}/status
    API->>+DB: SELECT status, result FROM jobs WHERE id = ?
    DB-->>-API: Job data
    API-->>-Client: 200 OK {status, result}
```

## OAuth2 Flow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
sequenceDiagram
    accTitle: OAuth2 PKCE Authorization Flow
    accDescr: Full OAuth2 flow with PKCE challenge, code exchange, and token-based API access.
    participant User
    participant App as Your App
    participant Auth as OAuth Provider
    participant API as Your API

    User->>+App: Click "Login with Provider"
    App->>App: Generate state, PKCE verifier
    App->>+Auth: Redirect to /authorize?<br/>client_id&redirect_uri&state&code_challenge

    User->>+Auth: Enter credentials
    Auth->>Auth: Authenticate user
    Auth-->>-User: Redirect to callback with code

    User->>+App: Callback with ?code&state
    App->>App: Verify state
    App->>+Auth: POST /token<br/>{code, code_verifier, client_secret}
    Auth->>Auth: Validate code & PKCE
    Auth-->>-App: {access_token, refresh_token, id_token}

    App->>+API: GET /user/profile<br/>Authorization: Bearer {token}
    API->>API: Validate token
    API-->>-App: User profile
    App-->>-User: Logged in dashboard
```

## Usage Instructions

1. Copy the relevant flow template
2. Rename participants to match your system
3. Adjust endpoints and payloads
4. Add/remove steps as needed
5. Include `accTitle` and `accDescr` for accessibility
6. Test in [Mermaid Live Editor](https://mermaid.live/)

## Tips

- Use `autonumber` to add step numbers
- Use `+/-` for activation (lifeline highlighting)
- Use `Note over` for section headers
- Use `alt/else`, `par/and`, `critical/option` for branching (see cross-portal-flow.md)
- Group related calls with blank lines
- Always include the Firefly theme init block
