# TravelMeetupApp - Project Goals & Technical Specifications

## Project Overview

The goal of this app is to help people keep track of where their friends are in the world, what they're up to, and notify them if they're visiting somewhere closeby.

For example, if I'm visiting New York City in two weeks from now, I'd like to be able to log my travel plans, and then get information about which of my connections (aka friends/acquaintances) are currently in New York City during my travel (which means that they do not have travel plans for that duration).

People should be able to look for and connect with people on the app, similar to how modern social media, especially Instagram and LinkedIn, function.

**Key Requirements:**
- Maintain a SQL database to store all relevant information for this app
- Build a backend API (just the API for now) which allows us to perform all required operations
- Public-facing application with appropriate security standards
- User accounts with secure logins and authentication
- Hosted in Azure (utilizing $150 monthly credits)
- Version control via GitHub with GitHub Actions for CI/CD
- Extensive API documentation for multiple client platforms

**Client Platforms:**
- Web app
- Android mobile app
- iPhone mobile app (developed by external developer - requires excellent API documentation)

---

## 1. Feature Specifications

### 1.1 User Registration & Authentication
**User Story:** As a new user, I want to create an account so that I can access the app and connect with friends.

**Acceptance Criteria:**
- User can register with email and password
- Email must be unique in the system
- Password must meet security requirements (see Security section)
- User receives confirmation of successful registration
- User can log in with email and password
- User receives JWT access token and refresh token upon successful login
- User can refresh access token using refresh token
- User can log out (token invalidation)

### 1.2 User Profile Management
**User Story:** As a user, I want to manage my profile so that my connections can learn more about me.

**Acceptance Criteria:**
- User can view their own profile
- User can update profile information (display name, bio, profile picture, home city)
- User can view other users' public profiles
- Profile includes display name, bio, profile picture, home city, and join date
- User can search for other users by name or email

### 1.3 Connection System (Bidirectional)
**User Story:** As a user, I want to connect with friends so that we can share travel plans and meet up.

**Acceptance Criteria:**
- User can search for other users by name or email
- User can send connection request to another user
- User receives notification of incoming connection request
- User can accept or reject connection requests
- Connection becomes active only when both parties approve (bidirectional/mutual)
- User can view list of their connections
- User can view pending connection requests (sent and received)
- User can remove an existing connection

### 1.4 Travel Plan Management
**User Story:** As a user, I want to log my travel plans so that my connections know when I'll be visiting different cities.

**Acceptance Criteria:**
- User can create a travel plan with city, country, start date, end date, and optional description
- User can view their own travel plans
- User can update existing travel plans
- User can delete travel plans
- User can view upcoming vs. past travel plans
- Travel plans are visible only to approved connections (connections-only visibility)
- System validates that start date is before end date

### 1.5 Travel Matching Algorithm
**User Story:** As a user, I want to see which of my connections will be in the same city during my travels so that we can meet up.

**Acceptance Criteria:**
- User can query for connections who will be in a specific city during a date range
- System returns connections whose travel plans overlap with the query date range in the same city
- System also returns connections whose home city matches the query city (if they have no travel plans during that period)
- Results include connection's name, profile picture, and travel dates or home city status
- Matching is city-based (simple string matching initially)
- User can view travel matches for any of their own travel plans

### 1.6 Notifications (Polling-Based)
**User Story:** As a user, I want to be notified of important events so that I stay informed about connection requests and travel matches.

**Acceptance Criteria:**
- System generates notifications for: new connection requests, accepted connection requests, new travel matches
- User can retrieve their notifications (polling endpoint)
- User can mark notifications as read
- User can view count of unread notifications
- Notifications include type, message, timestamp, and related entity ID
- Notifications are ordered by most recent first

---

## 2. Technology Stack

### 2.1 Backend Framework
- **Language:** Python 3.11+
- **Framework:** FastAPI (async support, high performance, automatic API documentation)
- **ASGI Server:** Uvicorn (for local development and production)

### 2.2 Database & ORM
- **Database:** Azure SQL Database
- **ORM:** SQLAlchemy (with async support via `asyncpg` or `pyodbc` for Azure SQL)
- **Validation:** Pydantic models for request/response validation
- **Migrations:** Alembic for database schema version control

### 2.3 Authentication & Security
- **JWT Tokens:** `python-jose[cryptography]` for JWT creation and validation
- **Password Hashing:** `passlib` with bcrypt algorithm
- **Environment Variables:** `python-dotenv` for local development
- **Azure SDK:** `azure-identity` for Azure service authentication

### 2.4 Azure Services
- **Compute:** Azure App Service (Linux, Python 3.11 runtime)
- **Database:** Azure SQL Database (Basic/Standard tier)
- **Secrets Management:** Azure Key Vault
- **Monitoring:** Azure Application Insights
- **CI/CD:** GitHub Actions for automated deployment

### 2.5 Development & Testing
- **Testing Framework:** pytest with FastAPI TestClient
- **Code Quality:** pylint or flake8 for linting
- **API Documentation:** FastAPI auto-generated Swagger UI at `/docs` + separate markdown reference guide
- **Version Control:** Git with GitHub

### 2.6 Python Dependencies
```
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
alembic==1.13.1
pydantic==2.5.3
pydantic-settings==2.1.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pyodbc==5.0.1  # For Azure SQL
azure-identity==1.15.0
python-dotenv==1.0.0
pytest==7.4.4
httpx==0.26.0  # For TestClient
```

---

## 3. Database Schema

### 3.1 Entity Relationship Overview
- **Users** have many **Connections** (bidirectional many-to-many through connection requests)
- **Users** have many **Travel Plans** (one-to-many)
- **Users** have many **Notifications** (one-to-many)

### 3.2 Tables & SQL DDL

#### 3.2.1 Users Table
```sql
CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    display_name NVARCHAR(100) NOT NULL,
    bio NVARCHAR(500) NULL,
    profile_pic_url NVARCHAR(500) NULL,
    home_city NVARCHAR(100) NULL,
    home_country NVARCHAR(100) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_display_name ON users(display_name);
```

#### 3.2.2 Connections Table
```sql
CREATE TABLE connections (
    id INT PRIMARY KEY IDENTITY(1,1),
    requester_user_id INT NOT NULL,
    receiver_user_id INT NOT NULL,
    status NVARCHAR(20) NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_user_id) REFERENCES users(id) ON DELETE NO ACTION,
    CONSTRAINT unique_connection UNIQUE (requester_user_id, receiver_user_id)
);

CREATE INDEX idx_connections_requester ON connections(requester_user_id);
CREATE INDEX idx_connections_receiver ON connections(receiver_user_id);
CREATE INDEX idx_connections_status ON connections(status);
```

**Note:** Bidirectional connections are modeled as a single row where `requester_user_id` sends a request to `receiver_user_id`. When status is 'accepted', both users are considered connected.

#### 3.2.3 Travel Plans Table
```sql
CREATE TABLE travel_plans (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    city NVARCHAR(100) NOT NULL,
    country NVARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description NVARCHAR(1000) NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT check_dates CHECK (start_date <= end_date)
);

CREATE INDEX idx_travel_plans_user ON travel_plans(user_id);
CREATE INDEX idx_travel_plans_dates ON travel_plans(start_date, end_date);
CREATE INDEX idx_travel_plans_city ON travel_plans(city, country);
```

#### 3.2.4 Notifications Table
```sql
CREATE TABLE notifications (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    type NVARCHAR(50) NOT NULL CHECK (type IN ('connection_request', 'connection_accepted', 'travel_match')),
    message NVARCHAR(500) NOT NULL,
    related_entity_id INT NULL,  -- ID of connection or travel_plan depending on type
    is_read BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
```

---

## 4. API Architecture

### 4.1 API Design Principles
- **RESTful Design:** Resources accessed via standard HTTP methods (GET, POST, PUT, DELETE)
- **Versioning:** All endpoints prefixed with `/api/v1/` for future version management
- **JSON Format:** All requests and responses use JSON
- **Status Codes:** Standard HTTP status codes (200, 201, 400, 401, 403, 404, 500)
- **Authentication:** JWT Bearer token in Authorization header for protected endpoints
- **Pagination:** Cursor-based pagination for list endpoints (limit & offset parameters)
- **Error Handling:** Consistent error response format across all endpoints

### 4.2 Authentication Flow
1. User registers via `POST /api/v1/auth/register`
2. User logs in via `POST /api/v1/auth/login` → receives `access_token` (15min expiry) and `refresh_token` (7 day expiry)
3. User includes access token in Authorization header: `Authorization: Bearer <access_token>`
4. When access token expires, user refreshes via `POST /api/v1/auth/refresh` with refresh token
5. For logout, client discards tokens (server-side token blacklist optional for Phase 2)

### 4.3 API Endpoints Overview

#### 4.3.1 Authentication Endpoints (`/api/v1/auth`)
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and receive tokens
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Logout (optional token blacklist)

#### 4.3.2 User Endpoints (`/api/v1/users`)
- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update current user profile
- `GET /users/{user_id}` - Get user profile by ID (public info only)
- `GET /users/search?q={query}` - Search users by name or email

#### 4.3.3 Connection Endpoints (`/api/v1/connections`)
- `GET /connections` - Get all connections (accepted only)
- `POST /connections/request` - Send connection request
- `GET /connections/requests/received` - Get received pending requests
- `GET /connections/requests/sent` - Get sent pending requests
- `PUT /connections/{connection_id}/accept` - Accept connection request
- `PUT /connections/{connection_id}/reject` - Reject connection request
- `DELETE /connections/{connection_id}` - Remove connection

#### 4.3.4 Travel Plan Endpoints (`/api/v1/travels`)
- `GET /travels` - Get current user's travel plans
- `POST /travels` - Create new travel plan
- `GET /travels/{travel_id}` - Get specific travel plan
- `PUT /travels/{travel_id}` - Update travel plan
- `DELETE /travels/{travel_id}` - Delete travel plan
- `GET /travels/{travel_id}/matches` - Get connections in same city during travel dates

#### 4.3.5 Notification Endpoints (`/api/v1/notifications`)
- `GET /notifications` - Get user's notifications (with pagination)
- `PUT /notifications/{notification_id}/read` - Mark notification as read
- `PUT /notifications/read-all` - Mark all notifications as read
- `GET /notifications/unread-count` - Get count of unread notifications

### 4.4 Example API Requests & Responses

#### Example 1: User Login
**Request:**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900,
  "user": {
    "id": 123,
    "email": "john.doe@example.com",
    "display_name": "John Doe",
    "profile_pic_url": "https://example.com/profiles/123.jpg",
    "home_city": "San Francisco",
    "home_country": "USA"
  }
}
```

#### Example 2: Create Travel Plan
**Request:**
```http
POST /api/v1/travels
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "city": "New York",
  "country": "USA",
  "start_date": "2026-03-15",
  "end_date": "2026-03-20",
  "description": "Business conference and sightseeing"
}
```

**Response (201 Created):**
```json
{
  "id": 456,
  "user_id": 123,
  "city": "New York",
  "country": "USA",
  "start_date": "2026-03-15",
  "end_date": "2026-03-20",
  "description": "Business conference and sightseeing",
  "created_at": "2026-01-31T10:30:00Z",
  "updated_at": "2026-01-31T10:30:00Z"
}
```

#### Example 3: Get Travel Matches
**Request:**
```http
GET /api/v1/travels/456/matches
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200 OK):**
```json
{
  "travel_plan": {
    "id": 456,
    "city": "New York",
    "country": "USA",
    "start_date": "2026-03-15",
    "end_date": "2026-03-20"
  },
  "matches": [
    {
      "user_id": 789,
      "display_name": "Jane Smith",
      "profile_pic_url": "https://example.com/profiles/789.jpg",
      "match_type": "traveling",
      "travel_plan": {
        "id": 321,
        "start_date": "2026-03-14",
        "end_date": "2026-03-18",
        "description": "Family vacation"
      }
    },
    {
      "user_id": 890,
      "display_name": "Bob Johnson",
      "profile_pic_url": "https://example.com/profiles/890.jpg",
      "match_type": "home_city",
      "home_city": "New York",
      "home_country": "USA"
    }
  ],
  "total_matches": 2
}
```

### 4.5 Error Response Format
All error responses follow this structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "timestamp": "2026-01-31T10:30:00Z"
}
```

**Common Error Codes:**
- `VALIDATION_ERROR` (400) - Invalid request data
- `UNAUTHORIZED` (401) - Missing or invalid authentication token
- `FORBIDDEN` (403) - Insufficient permissions
- `NOT_FOUND` (404) - Resource not found
- `CONFLICT` (409) - Resource conflict (e.g., duplicate email)
- `RATE_LIMIT_EXCEEDED` (429) - Too many requests
- `INTERNAL_ERROR` (500) - Server error

### 4.6 Pagination Format
List endpoints support pagination with query parameters:

**Request:**
```http
GET /api/v1/travels?limit=20&offset=0
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "limit": 20,
    "offset": 0,
    "total": 45,
    "has_more": true
  }
}
```

### 4.7 Security Requirements

#### 4.7.1 Password Policy
- Minimum 8 characters
- Must contain at least:
  - One uppercase letter (A-Z)
  - One lowercase letter (a-z)
  - One number (0-9)
  - One special character (!@#$%^&*()_+-=[]{}|;:,.<>?)
- Password strength validation on registration and password change

#### 4.7.2 Rate Limiting
- **Authentication Endpoints:** 10 requests per minute per IP
- **General API Endpoints:** 100 requests per minute per user
- **Search Endpoints:** 30 requests per minute per user
- Rate limit headers included in responses:
  ```
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 95
  X-RateLimit-Reset: 1643721600
  ```

#### 4.7.3 Transport Security
- **HTTPS Only:** All production traffic must use HTTPS (TLS 1.2+)
- **HSTS:** HTTP Strict Transport Security header enabled
- **Secure Cookies:** SameSite and Secure flags for any cookies (if used)

#### 4.7.4 CORS Configuration
- **Allowed Origins:** Whitelist of approved domains (web app, admin panel)
- **Allowed Methods:** GET, POST, PUT, DELETE, OPTIONS
- **Allowed Headers:** Authorization, Content-Type
- **Credentials:** Allow credentials for authenticated requests
- **Max Age:** 3600 seconds for preflight caching

#### 4.7.5 SQL Injection Prevention
- **Parameterized Queries:** SQLAlchemy ORM handles parameterization automatically
- **Input Validation:** Pydantic models validate and sanitize all inputs
- **No Raw SQL:** Avoid raw SQL queries; use ORM query builder

#### 4.7.6 JWT Token Security
- **Access Token Expiry:** 15 minutes
- **Refresh Token Expiry:** 7 days
- **Token Storage:** Clients must store tokens securely (secure storage on mobile, httpOnly cookies or localStorage with XSS protection on web)
- **Secret Key Rotation:** JWT secret key stored in Azure Key Vault, rotated every 90 days
- **Algorithm:** HS256 (HMAC with SHA-256)

#### 4.7.7 Input Validation & Sanitization
- **Email Validation:** RFC-compliant email format
- **XSS Prevention:** HTML escape user-generated content (display names, bios, descriptions)
- **Length Limits:** Enforce maximum lengths for all string fields
- **Date Validation:** Ensure valid date formats and logical date ranges

#### 4.7.8 Privacy & Data Protection
- **Travel Plan Visibility:** Connections-only by default (no public travel plans)
- **Profile Privacy:** Email addresses not exposed in public profiles
- **Data Minimization:** Only collect necessary information
- **GDPR Consideration:** Include user data deletion capability (Phase 2)

---

## 5. Azure Infrastructure

### 5.1 Azure Services Architecture

#### 5.1.1 Azure App Service
- **Service Type:** App Service (Web App)
- **Operating System:** Linux
- **Runtime Stack:** Python 3.11
- **Pricing Tier (MVP):** B1 Basic (1 Core, 1.75 GB RAM, $13.14/month)
- **Scaling Tier (Production):** S1 Standard (1 Core, 1.75 GB RAM, $69.35/month) with autoscaling
- **Deployment:** GitHub Actions using Azure Web Apps Deploy action
- **Configuration:**
  - Always On: Enabled (for S1+)
  - HTTP/2: Enabled
  - HTTPS Only: Enabled
  - Minimum TLS Version: 1.2
  - ARR Affinity: Disabled (for stateless API)

#### 5.1.2 Azure SQL Database
- **Service Type:** Azure SQL Database (Single Database)
- **Pricing Tier (Development):** Basic (5 DTUs, 2 GB storage, $4.90/month)
- **Pricing Tier (Production):** S0 Standard (10 DTUs, 250 GB storage, $15/month)
- **Scaling Path:** S1 (20 DTUs), S2 (50 DTUs) as needed
- **Configuration:**
  - Connection Pooling: Enabled via SQLAlchemy (pool_size=5, max_overflow=10)
  - Backup Retention: 7 days (automatic)
  - Geo-Replication: Optional for Phase 2
  - Firewall Rules: Allow Azure services + development IPs
  - Connection String: Stored in Azure Key Vault

#### 5.1.3 Azure Key Vault
- **Service Type:** Key Vault (Standard tier)
- **Pricing:** ~$0.03/month (per 10,000 operations)
- **Secrets Stored:**
  - `DATABASE-CONNECTION-STRING` - Azure SQL connection string
  - `JWT-SECRET-KEY` - Secret key for JWT token signing
  - `JWT-REFRESH-SECRET-KEY` - Secret key for refresh tokens
- **Access Policy:** Managed identity for App Service
- **Configuration:**
  - Soft Delete: Enabled (90 day retention)
  - Purge Protection: Enabled
  - Access via azure-identity SDK in code

#### 5.1.4 Azure Application Insights
- **Service Type:** Application Insights (part of Azure Monitor)
- **Pricing:** Pay-as-you-go (~$2.30/GB ingested, first 5GB/month free)
- **Monitoring:**
  - Request tracking (response times, status codes)
  - Exception logging with stack traces
  - Custom events (user actions, travel matches found)
  - Performance metrics (CPU, memory, database query times)
  - Dependency tracking (SQL queries)
- **Integration:** Python SDK via OpenCensus Azure Monitor exporter

### 5.2 Environment Configuration

#### 5.2.1 Local Development (.env file)
```bash
# Database
DATABASE_URL=mssql+pyodbc://username:password@localhost/travelmeetup?driver=ODBC+Driver+18+for+SQL+Server

# JWT
JWT_SECRET_KEY=your-local-dev-secret-key-change-in-production
JWT_REFRESH_SECRET_KEY=your-local-dev-refresh-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Environment
ENVIRONMENT=development
DEBUG=True

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
```

#### 5.2.2 Production (Azure App Service Application Settings)
```bash
# Database (from Key Vault)
DATABASE_URL=@Microsoft.KeyVault(SecretUri=https://travelmeetup-kv.vault.azure.net/secrets/DATABASE-CONNECTION-STRING/)

# JWT (from Key Vault)
JWT_SECRET_KEY=@Microsoft.KeyVault(SecretUri=https://travelmeetup-kv.vault.azure.net/secrets/JWT-SECRET-KEY/)
JWT_REFRESH_SECRET_KEY=@Microsoft.KeyVault(SecretUri=https://travelmeetup-kv.vault.azure.net/secrets/JWT-REFRESH-SECRET-KEY/)
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Environment
ENVIRONMENT=production
DEBUG=False

# CORS
CORS_ORIGINS=https://travelmeetup.com,https://www.travelmeetup.com

# Application Insights
APPINSIGHTS_INSTRUMENTATION_KEY=your-instrumentation-key
```

### 5.3 Cost Breakdown (Monthly)

| Service | Tier | Monthly Cost |
|---------|------|--------------|
| Azure App Service | B1 Basic (MVP) | $13.14 |
| Azure App Service | S1 Standard (Prod) | $69.35 |
| Azure SQL Database | Basic (Dev) | $4.90 |
| Azure SQL Database | S0 Standard (Prod) | $15.00 |
| Azure Key Vault | Standard | $0.03 |
| Application Insights | Pay-as-you-go | $0-2.00 |
| **Total (Development)** | | **~$18-20** |
| **Total (Production Scale)** | | **~$86-88** |

**Budget Status:** Well within $150/month allocation, with room for growth and additional services (e.g., Azure Cache for Redis, Azure CDN for profile images)

### 5.4 Infrastructure as Code (Bicep)

#### 5.4.1 Why Bicep?
We'll use **Azure Bicep** for Infrastructure as Code to:
- **Version control** infrastructure alongside application code
- **Automate** environment creation and updates via GitHub Actions
- **Ensure consistency** between dev, staging, and production environments
- **Document** infrastructure configuration as code
- **Reduce costs** by easily tearing down/recreating dev environments
- **Simplify disaster recovery** with reproducible infrastructure

**Benefits over manual setup:**
- No clicking through Azure Portal
- Repeatable deployments
- Built-in dependency management
- Native Azure support with excellent VS Code tooling

#### 5.4.2 Project Structure
```
TravelMeetupApp/
├── infrastructure/
│   ├── main.bicep                    # Main infrastructure template
│   ├── modules/
│   │   ├── appService.bicep         # App Service module
│   │   ├── sqlDatabase.bicep        # SQL Database module
│   │   ├── keyVault.bicep           # Key Vault module
│   │   └── appInsights.bicep        # Application Insights module
│   ├── parameters.dev.json           # Development environment parameters
│   ├── parameters.prod.json          # Production environment parameters
│   └── README.md                     # Deployment instructions
├── .github/
│   └── workflows/
│       ├── infrastructure-deploy.yml # Deploy infrastructure changes
│       └── app-deploy.yml            # Deploy application code
```

#### 5.4.3 Main Bicep Template (infrastructure/main.bicep)
```bicep
// Main infrastructure template for TravelMeetupApp

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Application name prefix')
param appNamePrefix string = 'travelmeetup'

@description('SQL Admin username')
@secure()
param sqlAdminUsername string

@description('SQL Admin password')
@secure()
param sqlAdminPassword string

@description('JWT Secret Key')
@secure()
param jwtSecretKey string

@description('JWT Refresh Secret Key')
@secure()
param jwtRefreshSecretKey string

// Variables
var appServicePlanName = '${appNamePrefix}-plan-${environment}'
var webAppName = '${appNamePrefix}-api-${environment}'
var sqlServerName = '${appNamePrefix}-sql-${environment}'
var sqlDatabaseName = '${appNamePrefix}-db-${environment}'
var keyVaultName = '${appNamePrefix}-kv-${environment}'
var appInsightsName = '${appNamePrefix}-ai-${environment}'

// App Service Plan SKU based on environment
var appServicePlanSku = environment == 'prod' ? {
  name: 'S1'
  tier: 'Standard'
  capacity: 1
} : {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

// SQL Database SKU based on environment
var sqlDatabaseSku = environment == 'prod' ? {
  name: 'S0'
  tier: 'Standard'
} : {
  name: 'Basic'
  tier: 'Basic'
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: appServicePlanSku
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// App Service (Web App)
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: environment == 'prod' ? true : false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'DEBUG'
          value: environment == 'dev' ? 'True' : 'False'
        }
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/DATABASE-CONNECTION-STRING/)'
        }
        {
          name: 'JWT_SECRET_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/JWT-SECRET-KEY/)'
        }
        {
          name: 'JWT_REFRESH_SECRET_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/JWT-REFRESH-SECRET-KEY/)'
        }
        {
          name: 'JWT_ALGORITHM'
          value: 'HS256'
        }
        {
          name: 'ACCESS_TOKEN_EXPIRE_MINUTES'
          value: '15'
        }
        {
          name: 'REFRESH_TOKEN_EXPIRE_DAYS'
          value: '7'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATION_KEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: sqlDatabaseSku
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// SQL Firewall Rule - Allow Azure Services
resource sqlFirewallAzure 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// Key Vault Secrets
resource kvSecretDbConnection 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'DATABASE-CONNECTION-STRING'
  properties: {
    value: 'mssql+pyodbc://${sqlAdminUsername}:${sqlAdminPassword}@${sqlServer.properties.fullyQualifiedDomainName}:1433/${sqlDatabaseName}?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=no'
  }
}

resource kvSecretJwt 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'JWT-SECRET-KEY'
  properties: {
    value: jwtSecretKey
  }
}

resource kvSecretJwtRefresh 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'JWT-REFRESH-SECRET-KEY'
  properties: {
    value: jwtRefreshSecretKey
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// Log Analytics Workspace (required for App Insights)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${appNamePrefix}-logs-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// Outputs
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output keyVaultName string = keyVault.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
```

#### 5.4.4 Parameter Files

**Development Environment (infrastructure/parameters.dev.json):**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "dev"
    },
    "location": {
      "value": "eastus"
    },
    "appNamePrefix": {
      "value": "travelmeetup"
    },
    "sqlAdminUsername": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "sql-admin-username"
      }
    },
    "sqlAdminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "sql-admin-password"
      }
    },
    "jwtSecretKey": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "jwt-secret-dev"
      }
    },
    "jwtRefreshSecretKey": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "jwt-refresh-secret-dev"
      }
    }
  }
}
```

**Production Environment (infrastructure/parameters.prod.json):**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "prod"
    },
    "location": {
      "value": "eastus"
    },
    "appNamePrefix": {
      "value": "travelmeetup"
    },
    "sqlAdminUsername": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "sql-admin-username"
      }
    },
    "sqlAdminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "sql-admin-password"
      }
    },
    "jwtSecretKey": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "jwt-secret-prod"
      }
    },
    "jwtRefreshSecretKey": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
        },
        "secretName": "jwt-refresh-secret-prod"
      }
    }
  }
}
```

#### 5.4.5 Deployment Commands

**Prerequisites:**
```bash
# Install Azure CLI
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# Install Bicep CLI (usually comes with Azure CLI)
az bicep install
```

**Manual Deployment:**
```bash
# Create resource group (one-time)
az group create \
  --name travelmeetup-rg-dev \
  --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group travelmeetup-rg-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.dev.json

# For production
az group create \
  --name travelmeetup-rg-prod \
  --location eastus

az deployment group create \
  --resource-group travelmeetup-rg-prod \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.prod.json
```

**What-If Deployment (Preview Changes):**
```bash
# See what would change without actually deploying
az deployment group what-if \
  --resource-group travelmeetup-rg-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.dev.json
```

**Validate Template:**
```bash
# Validate Bicep template syntax
az deployment group validate \
  --resource-group travelmeetup-rg-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.dev.json
```

#### 5.4.6 GitHub Actions Workflow for Infrastructure

**File: .github/workflows/infrastructure-deploy.yml**
```yaml
name: Deploy Infrastructure

on:
  push:
    branches:
      - main
    paths:
      - 'infrastructure/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - prod

permissions:
  id-token: write
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Validate Bicep Template
        run: |
          az deployment group validate \
            --resource-group travelmeetup-rg-${{ github.event.inputs.environment || 'dev' }} \
            --template-file infrastructure/main.bicep \
            --parameters infrastructure/parameters.${{ github.event.inputs.environment || 'dev' }}.json

  preview:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: What-If Deployment
        run: |
          az deployment group what-if \
            --resource-group travelmeetup-rg-${{ github.event.inputs.environment || 'dev' }} \
            --template-file infrastructure/main.bicep \
            --parameters infrastructure/parameters.${{ github.event.inputs.environment || 'dev' }}.json

  deploy:
    runs-on: ubuntu-latest
    needs: [validate, preview]
    environment: ${{ github.event.inputs.environment || 'dev' }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Infrastructure
        run: |
          az deployment group create \
            --resource-group travelmeetup-rg-${{ github.event.inputs.environment || 'dev' }} \
            --template-file infrastructure/main.bicep \
            --parameters infrastructure/parameters.${{ github.event.inputs.environment || 'dev' }}.json \
            --verbose
      
      - name: Get Deployment Outputs
        id: deploy_output
        run: |
          outputs=$(az deployment group show \
            --resource-group travelmeetup-rg-${{ github.event.inputs.environment || 'dev' }} \
            --name main \
            --query properties.outputs)
          echo "outputs=$outputs" >> $GITHUB_OUTPUT
      
      - name: Display Outputs
        run: |
          echo "Deployment completed successfully!"
          echo "Web App URL: ${{ fromJson(steps.deploy_output.outputs.outputs).webAppUrl.value }}"
```

#### 5.4.7 Initial Setup Steps

**Step 1: Create Initial Key Vault for Secrets (One-Time Setup)**
```bash
# Create a separate Key Vault for storing deployment secrets
az keyvault create \
  --name travelmeetup-secrets-kv \
  --resource-group travelmeetup-secrets-rg \
  --location eastus

# Add secrets
az keyvault secret set \
  --vault-name travelmeetup-secrets-kv \
  --name sql-admin-username \
  --value "sqladmin"

az keyvault secret set \
  --vault-name travelmeetup-secrets-kv \
  --name sql-admin-password \
  --value "YourSecurePassword123!"

az keyvault secret set \
  --vault-name travelmeetup-secrets-kv \
  --name jwt-secret-dev \
  --value "your-jwt-secret-key-for-dev-at-least-32-chars"

az keyvault secret set \
  --vault-name travelmeetup-secrets-kv \
  --name jwt-refresh-secret-dev \
  --value "your-jwt-refresh-secret-key-for-dev-at-least-32-chars"

az keyvault secret set \
  --vault-name travelmeetup-secrets-kv \
  --name jwt-secret-prod \
  --value "your-jwt-secret-key-for-prod-at-least-32-chars"

az keyvault secret set \
  --vault-name travelmeetup-secrets-kv \
  --name jwt-refresh-secret-prod \
  --value "your-jwt-refresh-secret-key-for-prod-at-least-32-chars"
```

**Step 2: Update Parameter Files**
Update the Key Vault references in `parameters.dev.json` and `parameters.prod.json` with your actual subscription ID, resource group, and Key Vault name.

**Step 3: Setup GitHub Secrets**
Create Azure service principal for GitHub Actions:
```bash
az ad sp create-for-rbac \
  --name "github-actions-travelmeetup" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/travelmeetup-rg-dev \
  --sdk-auth
```

Add the output JSON as GitHub secret: `AZURE_CREDENTIALS`

**Step 4: Deploy**
```bash
# Commit infrastructure code
git add infrastructure/
git commit -m "Add infrastructure as code"
git push

# Infrastructure will deploy automatically via GitHub Actions
# Or trigger manually from Actions tab
```

#### 5.4.8 Benefits of This Approach

1. **Automated Deployments** - Push to main triggers infrastructure updates
2. **Environment Isolation** - Separate dev/prod with different SKUs and costs
3. **Security** - Secrets stored in Key Vault, not in code
4. **Cost Control** - Easily tear down dev environment when not needed
5. **Disaster Recovery** - Rebuild entire infrastructure with one command
6. **Documentation** - Infrastructure is self-documenting through code
7. **Change Tracking** - All infrastructure changes tracked in Git
8. **Preview Changes** - What-if analysis before applying changes

### 5.5 Database Connection Management

#### 5.5.1 SQLAlchemy Engine Configuration
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

engine = create_async_engine(
    DATABASE_URL,
    echo=False,  # Set to True for SQL query logging in dev
    pool_size=5,  # Number of connections to maintain
    max_overflow=10,  # Additional connections when pool is full
    pool_pre_ping=True,  # Verify connections before using
    pool_recycle=3600,  # Recycle connections after 1 hour
)

async_session_maker = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)
```

---

## 6. Development Roadmap

### 6.1 Phase 1: Foundation & Authentication (Weeks 1-2)

#### Objectives
- Setup project structure and development environment
- Implement authentication system with JWT
- Deploy database schema to Azure SQL
- Create basic user CRUD operations
- Deploy to Azure App Service

#### Tasks
1. **Infrastructure Setup (Bicep)**
   - Create infrastructure/ directory with Bicep templates
   - Create secrets Key Vault and store credentials
   - Deploy infrastructure using Bicep to Azure (dev environment)
   - Verify all resources are provisioned correctly
   - Setup GitHub Actions workflow for infrastructure deployments
   - Document infrastructure deployment process

2. **Project Setup**
   - Initialize Python project with FastAPI
   - Setup virtual environment and install dependencies
   - Configure project structure (routers, models, schemas, services)
   - Connect to Azure SQL Database
   - Setup Application Insights integration

3. **Database Schema**
   - Create Alembic migrations for all tables
   - Deploy initial schema to Azure SQL Database
   - Setup database connection with SQLAlchemy
   - Create SQLAlchemy models for all entities

3. **Authentication System**
   - Implement user registration endpoint (`POST /auth/register`)
   - Implement password hashing with bcrypt
   - Implement login endpoint with JWT generation (`POST /auth/login`)
   - Implement token refresh endpoint (`POST /auth/refresh`)
   - Create authentication dependency for protected routes
   - Add password validation (complexity requirements)

4. **User Management**
   - Implement get current user endpoint (`GET /users/me`)
   - Implement update user profile endpoint (`PUT /users/me`)
   - Implement get user by ID endpoint (`GET /users/{user_id}`)
   - Implement user search endpoint (`GET /users/search`)

5. **Testing**
   - Write unit tests for authentication logic
   - Write API integration tests with TestClient
   - Setup test database configuration
   - Achieve >80% code coverage

6. **Deployment**
   - Verify infrastructure is deployed via Bicep
   - Configure GitHub Actions workflow for application deployment
   - Deploy FastAPI application to Azure App Service
   - Verify API is accessible and functional
   - Test all endpoints using Swagger UI

**Deliverables:**
- Complete Azure infrastructure deployed via Bicep (IaC)
- Functional authentication system
- User registration and profile management
- Deployed API on Azure App Service with CI/CD
- Comprehensive test suite

### 6.2 Phase 2: Connections & Travel Plans (Weeks 3-4)

#### Objectives
- Implement bidirectional connection system
- Create travel plan CRUD operations
- Build city-based matching algorithm
- Generate notifications for matches and connections

#### Tasks
1. **Connection System**
   - Implement send connection request endpoint (`POST /connections/request`)
   - Implement get connections endpoint (`GET /connections`)
   - Implement get pending requests endpoints (sent/received)
   - Implement accept connection endpoint (`PUT /connections/{id}/accept`)
   - Implement reject connection endpoint (`PUT /connections/{id}/reject`)
   - Implement remove connection endpoint (`DELETE /connections/{id}`)
   - Add validation to prevent duplicate connections
   - Generate notification on connection request
   - Generate notification on connection acceptance

2. **Travel Plan Management**
   - Implement create travel plan endpoint (`POST /travels`)
   - Implement get user's travel plans endpoint (`GET /travels`)
   - Implement get specific travel plan endpoint (`GET /travels/{id}`)
   - Implement update travel plan endpoint (`PUT /travels/{id}`)
   - Implement delete travel plan endpoint (`DELETE /travels/{id}`)
   - Add date validation (start_date < end_date)
   - Add query filters (upcoming vs. past travels)

3. **Travel Matching Algorithm**
   - Implement get travel matches endpoint (`GET /travels/{id}/matches`)
   - Build query to find connections in same city during date range
   - Include connections whose home city matches (no conflicting travel plans)
   - Optimize query with proper indexes
   - Format response with match type (traveling vs. home_city)
   - Generate notification when new match is found

4. **Testing & Optimization**
   - Write unit tests for connection logic
   - Write unit tests for travel matching algorithm
   - Write API integration tests for all new endpoints
   - Optimize database queries with explain plans
   - Add database indexes for performance

**Deliverables:**
- Fully functional connection system with bidirectional approval
- Travel plan CRUD operations
- Working travel match algorithm
- Notification generation for key events

### 6.3 Phase 3: Notifications & Polish (Week 5)

#### Objectives
- Implement notification retrieval system (polling)
- Add notification read status management
- Optimize API performance
- Complete API documentation

#### Tasks
1. **Notification System**
   - Implement get notifications endpoint (`GET /notifications`)
   - Add pagination support for notifications
   - Implement mark as read endpoint (`PUT /notifications/{id}/read`)
   - Implement mark all as read endpoint (`PUT /notifications/read-all`)
   - Implement unread count endpoint (`GET /notifications/unread-count`)
   - Add filtering (read vs. unread, by type)

2. **Performance Optimization**
   - Review and optimize all database queries
   - Add composite indexes for frequently joined tables
   - Implement connection pooling tuning
   - Add caching for frequently accessed data (optional)
   - Load testing with realistic user scenarios
   - Monitor Application Insights for bottlenecks

3. **API Documentation**
   - Verify FastAPI auto-generated Swagger UI at `/docs`
   - Create comprehensive markdown API reference guide
   - Document all endpoints with descriptions
   - Include request/response examples for each endpoint
   - Document authentication flow with diagrams
   - Add troubleshooting section for common errors
   - Create getting started guide for iPhone developer

4. **Security Hardening**
   - Implement rate limiting for all endpoints
   - Add input validation for all fields
   - Review CORS configuration
   - Verify HTTPS enforcement
   - Test authentication edge cases
   - Security audit of all endpoints

5. **Final Testing**
   - End-to-end testing of all user flows
   - Cross-browser testing of Swagger UI
   - Mobile client simulation tests
   - Load testing with expected production traffic
   - Fix any critical bugs

**Deliverables:**
- Complete notification system
- Optimized and performant API
- Comprehensive API documentation tailored for external developers
- Production-ready secure backend

### 6.4 Phase 4: Future Enhancements (Beyond MVP)

#### Objectives
- Add advanced features based on user feedback
- Implement real-time capabilities
- Enhance matching with geospatial features

#### Potential Features
1. **Geospatial Proximity Matching**
   - Integrate Geopy or Azure Maps API
   - Calculate distance between coordinates
   - Match users within configurable radius (e.g., 50km)
   - Replace simple city string matching with lat/long

2. **Real-Time Notifications**
   - Implement WebSocket support with FastAPI
   - Push notifications to mobile clients
   - Live updates for connection requests and matches
   - Azure SignalR Service integration (optional)

3. **Enhanced Privacy Controls**
   - Add privacy settings for travel plans (public/connections/private)
   - Control who can send connection requests
   - Block users functionality
   - Data export and account deletion (GDPR compliance)

4. **Social Features**
   - User profiles with posts/status updates
   - Photo sharing from travels
   - Travel recommendations based on friends' history
   - Travel groups/events

5. **Advanced Matching**
   - Match interests/preferences
   - Suggest users based on mutual connections
   - Travel history and patterns analysis
   - AI-powered recommendations

### 6.5 GitHub Actions CI/CD Workflows

#### 6.5.1 Workflow Overview
Two separate workflows handle infrastructure and application deployments:

1. **Infrastructure Deployment** (`infrastructure-deploy.yml`) - Deploys Azure resources via Bicep
   - Triggered on changes to `infrastructure/**` directory
   - Can be manually triggered with environment selection
   - Runs validation, what-if preview, and deployment
   
2. **Application Deployment** (`app-deploy.yml`) - Deploys FastAPI application code
   - Triggered on pull requests (runs tests only)
   - Triggered on push to main (runs tests + deploys to Azure)
   - Deploys to App Service using publish profile

#### 6.5.2 Application Deployment Workflow (.github/workflows/app-deploy.yml)
```yaml
name: Build and Deploy to Azure App Service

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

env:
  AZURE_WEBAPP_NAME: travelmeetup-api
  PYTHON_VERSION: '3.11'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-cov flake8
      
      - name: Lint with flake8
        run: |
          flake8 app/ --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 app/ --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
      
      - name: Run tests with pytest
        run: |
          pytest tests/ --cov=app --cov-report=xml --cov-report=term
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  deploy:
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      
      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }}
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: .
```

#### 6.5.3 Azure Setup for CI/CD
1. **For Infrastructure Deployment:**
   - Create service principal: `az ad sp create-for-rbac --role contributor --sdk-auth`
   - Add output as GitHub secret: `AZURE_CREDENTIALS`

2. **For Application Deployment:**
   - Download publish profile from Azure App Service (Deployment Center)
   - Add as GitHub secret: `AZURE_WEBAPP_PUBLISH_PROFILE`

Both workflows will automatically run based on their triggers. Infrastructure workflow is detailed in section 5.4.6.

### 6.6 Local Development Setup

#### 6.6.1 Prerequisites
- Python 3.11 or higher
- Azure SQL Database instance (or local SQL Server)
- Git
- Virtual environment tool (venv or conda)

#### 6.6.2 Setup Steps
```bash
# Clone repository
git clone https://github.com/yourusername/TravelMeetupApp.git
cd TravelMeetupApp

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file with local configuration
cp .env.example .env
# Edit .env with your local database credentials

# Run database migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# API will be available at http://localhost:8000
# Swagger UI at http://localhost:8000/docs
```

#### 6.6.3 Database Migrations with Alembic
```bash
# Create new migration after model changes
alembic revision --autogenerate -m "Description of changes"

# Apply migrations to database
alembic upgrade head

# Rollback last migration
alembic downgrade -1

# View migration history
alembic history
```

### 6.7 Testing Strategy

#### 6.7.1 Test Types
- **Unit Tests:** Test individual functions and business logic
- **Integration Tests:** Test API endpoints with TestClient
- **Database Tests:** Test database operations with test database
- **End-to-End Tests:** Test complete user workflows

#### 6.7.2 Test Structure
```
tests/
├── __init__.py
├── conftest.py              # Pytest fixtures
├── test_auth.py             # Authentication tests
├── test_users.py            # User management tests
├── test_connections.py      # Connection system tests
├── test_travels.py          # Travel plan tests
├── test_notifications.py    # Notification tests
└── test_matching.py         # Travel matching algorithm tests
```

#### 6.7.3 Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py

# Run tests matching pattern
pytest -k "test_login"

# Run with verbose output
pytest -v
```

---

## 7. API Documentation Strategy

### 7.1 Auto-Generated Documentation (FastAPI)
- **Swagger UI:** Available at `/docs` endpoint
- **ReDoc:** Available at `/redoc` endpoint (alternative UI)
- **OpenAPI Schema:** Available at `/openapi.json` for API client generation
- **Interactive Testing:** Swagger UI allows testing endpoints directly in browser

### 7.2 Markdown Reference Guide (For iPhone Developer)
A separate comprehensive markdown document will be created covering:
- **Getting Started:** Authentication flow, obtaining tokens
- **Endpoint Reference:** All endpoints with descriptions
- **Request Examples:** cURL and code examples for each endpoint
- **Response Examples:** Full JSON responses with field descriptions
- **Error Handling:** Common errors and how to handle them
- **Best Practices:** Rate limiting, pagination, token refresh strategy
- **Changelog:** Version history and breaking changes

This guide will be stored in `/docs/API_REFERENCE.md` and kept in sync with actual API implementation.

---

## 8. Success Metrics

### 8.1 Technical Metrics
- **API Response Time:** < 200ms for 95th percentile
- **Uptime:** > 99.5%
- **Test Coverage:** > 80%
- **Error Rate:** < 1% of requests

### 8.2 Development Metrics
- **Phase 1 Completion:** Week 2
- **Phase 2 Completion:** Week 4
- **Phase 3 Completion:** Week 5
- **Production Deployment:** Week 5

### 8.3 Documentation Metrics
- **API Documentation Complete:** By end of Phase 3
- **All endpoints documented with examples:** 100%
- **External developer onboarding time:** < 2 hours

---

## 9. Risk Management

### 9.1 Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Azure SQL costs exceed budget | High | Start with Basic tier, monitor usage, optimize queries, use Bicep to easily scale up/down |
| Performance issues with matching algorithm | Medium | Add proper indexes, implement caching, optimize queries |
| JWT token security breach | High | Use strong secrets in Key Vault, short expiration, token rotation |
| Database migration failure | Medium | Test migrations in dev environment, backup before prod migration |
| Infrastructure configuration errors | Medium | Use IaC (Bicep) with what-if previews, version control all infrastructure changes |

### 9.2 Project Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Timeline delays | Medium | Prioritize MVP features, defer Phase 4 enhancements |
| Scope creep | Medium | Strict adherence to phased roadmap, defer non-critical features |
| External developer struggles with API | High | Comprehensive documentation with examples, support channel |

---

## 10. Next Steps

1. **Review and Approve:** Review this document and approve technical approach
2. **Setup Azure Infrastructure:** 
   - Create initial secrets Key Vault (travelmeetup-secrets-kv)
   - Store SQL admin credentials and JWT secrets in Key Vault
   - Update parameter files with your subscription ID and Key Vault details
   - Deploy infrastructure using Bicep (see section 5.4 for complete instructions)
   - Verify all resources are created successfully
3. **Initialize Project:** Create FastAPI project structure with GitHub repository
4. **Configure GitHub Actions:** 
   - Create Azure service principal for deployments
   - Add AZURE_CREDENTIALS secret to GitHub
   - Setup infrastructure and application deployment workflows
5. **Begin Phase 1:** Start implementation following roadmap

---

## Document Version
- **Version:** 1.0
- **Last Updated:** January 31, 2026
- **Author:** Development Team
