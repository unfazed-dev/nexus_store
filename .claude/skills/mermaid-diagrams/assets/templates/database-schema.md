# Database Schema Template

Ready-to-use ER diagrams for documenting database schemas.

## Basic Schema

```mermaid
---
title: Basic Blog Schema
---
erDiagram
    %% User Management
    users {
        uuid id PK "Primary key"
        string email UK "Unique email"
        string password_hash "Hashed password"
        string name "Display name"
        boolean is_active "Account status"
        datetime created_at "Creation timestamp"
        datetime updated_at "Last update"
    }

    posts {
        uuid id PK
        uuid author_id FK "References users.id"
        string title
        text content
        string status "draft or published or archived"
        datetime published_at
        datetime created_at
        datetime updated_at
    }

    comments {
        uuid id PK
        uuid post_id FK "References posts.id"
        uuid author_id FK "References users.id"
        uuid parent_id FK "Self-reference for replies"
        text body
        datetime created_at
    }

    tags {
        uuid id PK
        string name UK
        string slug UK
    }

    post_tags {
        uuid post_id PK, FK
        uuid tag_id PK, FK
    }

    users ||--o{ posts : writes
    users ||--o{ comments : writes
    posts ||--o{ comments : has
    posts ||--o{ post_tags : "tagged with"
    tags ||--o{ post_tags : "applied to"
    comments ||--o{ comments : "replies to"
```

## E-Commerce Schema

```mermaid
---
title: E-Commerce Schema
---
erDiagram
    %% Customer domain
    customers {
        uuid id PK
        string email UK
        string name
        string phone
        datetime created_at
    }

    addresses {
        uuid id PK
        uuid customer_id FK
        string type "billing or shipping"
        string line1
        string line2
        string city
        string state
        string postal_code
        string country
        boolean is_default
    }

    %% Product domain
    products {
        uuid id PK
        string sku UK
        string name
        text description
        decimal price
        int stock_quantity
        boolean is_active
        datetime created_at
    }

    categories {
        uuid id PK
        string name UK
        string slug UK
        uuid parent_id FK
        int sort_order
    }

    product_categories {
        uuid product_id PK, FK
        uuid category_id PK, FK
    }

    %% Order domain
    orders {
        uuid id PK
        uuid customer_id FK
        uuid shipping_address_id FK
        uuid billing_address_id FK
        string status "pending or paid or shipped or delivered or cancelled"
        decimal subtotal
        decimal tax
        decimal shipping
        decimal total
        datetime ordered_at
    }

    order_items {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
        decimal unit_price
        decimal total
    }

    %% Relationships
    customers ||--o{ addresses : has
    customers ||--o{ orders : places
    orders ||--|{ order_items : contains
    products ||--o{ order_items : "ordered in"
    products ||--o{ product_categories : "belongs to"
    categories ||--o{ product_categories : contains
    categories ||--o{ categories : "parent of"
    addresses ||--o{ orders : "ships to"
```

## SaaS Multi-Tenant Schema

```mermaid
---
title: SaaS Multi-Tenant Schema
---
erDiagram
    %% Tenant management
    organizations {
        uuid id PK
        string name
        string slug UK
        string plan "free or starter or pro or enterprise"
        datetime created_at
    }

    users {
        uuid id PK
        uuid organization_id FK
        string email UK
        string name
        string role "owner or admin or member"
        datetime created_at
    }

    invitations {
        uuid id PK
        uuid organization_id FK
        string email
        string role
        string token UK
        datetime expires_at
        datetime accepted_at
    }

    %% Membership and Billing
    memberships {
        uuid id PK
        uuid organization_id FK, UK
        string membership_plan_id UK
        string status "active or inactive or cancelled"
        datetime start_date
        datetime end_date
    }

    %% Application data - tenant-scoped
    projects {
        uuid id PK
        uuid organization_id FK
        string name
        text description
        datetime created_at
    }

    %% Relationships
    organizations ||--o{ users : has
    organizations ||--o{ invitations : sends
    organizations ||--|| memberships : has
    organizations ||--o{ projects : owns
```

## Booking Domain Schema

```mermaid
---
title: Booking Domain Schema
---
erDiagram
    profiles {
        uuid id PK
        string email UK
        string first_name
        string last_name
        string user_type "customer or contractor or clm or admin"
        string preferences "JSONB"
        datetime created_at
    }

    customer_bookings {
        uuid id PK
        uuid customer_id FK
        uuid contractor_id FK
        uuid assigned_by FK "CLM who assigned"
        string status "8-status enum"
        timestamp start_time
        timestamp end_time
        timestamp original_start_time "Pre-reschedule"
        timestamp original_end_time "Pre-reschedule"
        string contractor_preference_ids "JSONB"
        text notes
        datetime created_at
    }

    invoices {
        uuid id PK
        uuid booking_id FK
        uuid customer_id FK
        string invoice_type "service or shop or credit_note or adjustment"
        string funding_management_type "nullable"
        decimal amount
        decimal tax
        decimal total
        string status "draft or pending or paid or voided"
        datetime created_at
    }

    wallet_accounts {
        uuid id PK
        uuid profile_id FK, UK
        decimal balance
        string currency "AUD"
        datetime created_at
    }

    wallet_transactions {
        uuid id PK
        uuid wallet_id FK
        uuid invoice_id FK
        string type "credit or debit"
        decimal amount
        string description
        datetime created_at
    }

    profiles ||--o{ customer_bookings : "requests as customer"
    profiles ||--o{ customer_bookings : "assigned as contractor"
    profiles ||--|| wallet_accounts : "has wallet"
    customer_bookings ||--o{ invoices : generates
    wallet_accounts ||--o{ wallet_transactions : has
    invoices ||--o{ wallet_transactions : "paid via"
```

## Usage Instructions

1. Copy the relevant schema template
2. Replace entities with your domain objects
3. Add/remove columns as needed
4. Define relationships using cardinality notation
5. Test in [Mermaid Live Editor](https://mermaid.live/)

## Cardinality Reference

| Notation | Meaning |
|----------|---------|
| `\|\|--\|\|` | One to one |
| `\|\|--o{` | One to many (optional) |
| `\|\|--\|{` | One to many (required) |
| `}o--o{` | Many to many |

## Column Type Annotations

| Annotation | Meaning |
|------------|---------|
| `PK` | Primary key |
| `FK` | Foreign key |
| `UK` | Unique constraint |
| `PK, FK` | Multiple constraints (comma-separated) |

## Tips

- Use `PK` for primary keys, `FK` for foreign keys, `UK` for unique
- Multiple constraints on one column: use commas (`PK, FK` not `PK FK`)
- Add comments in quotes for column descriptions — no double quotes inside
- Use `or` instead of commas in comment strings to avoid parser issues
- Keep entity names in lowercase snake_case
- Group related entities with `%%` comments
- Use JSONB for array columns synced via PowerSync (NOT TEXT[])
- ER diagrams support YAML frontmatter for titles but NOT `accTitle`/`accDescr`
