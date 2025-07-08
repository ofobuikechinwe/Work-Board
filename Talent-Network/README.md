# FreelanceHub: Decentralized Professional Services Marketplace

A trustless blockchain-based platform connecting freelancers with clients through secure smart contracts. Features automated escrow payments, reputation tracking, dispute resolution, and transparent project management.

## Overview

FreelanceHub eliminates intermediaries while ensuring fair compensation and quality service delivery through cryptographically-enforced agreements and community-driven arbitration. Built on the Stacks blockchain using Clarity smart contracts.

## Features

### Core Functionality
- **Trustless Escrow**: Automated payment release upon work completion
- **Reputation System**: Track freelancer performance and client reliability
- **Dispute Resolution**: Admin-mediated conflict resolution with evidence support
- **Milestone Tracking**: Break down complex projects into manageable phases
- **Profile Management**: Comprehensive freelancer and client profiles

### Security Features
- **Access Control**: Role-based permissions for different user types
- **Input Validation**: Comprehensive validation of all user inputs
- **Status Transitions**: Enforced contract lifecycle management
- **Platform Controls**: Admin tools for maintenance and fee management

## Contract Architecture

### Data Structures

#### Service Contracts
```clarity
{
  freelancer-address: principal,
  client-address: principal,
  project-start-date: uint,
  project-deadline: uint,
  contract-value: uint,
  current-status: string,
  project-description: string,
  payment-released: bool,
  completion-timestamp: optional uint
}
```

#### Freelancer Profiles
```clarity
{
  average-rating: uint,
  total-projects-completed: uint,
  successful-deliveries: uint,
  registration-date: uint,
  specialization-area: string,
  total-earnings: uint,
  is-verified: bool
}
```

#### Client Profiles
```clarity
{
  organization-name: string,
  total-projects-posted: uint,
  average-project-budget: uint,
  registration-date: uint,
  total-spent: uint,
  reputation-score: uint
}
```

## Contract Status Flow

1. **pending-acceptance** → Initial contract creation
2. **in-progress** → Freelancer accepts contract
3. **under-review** → Work submitted for client review
4. **completed** → Client approves and releases payment
5. **disputed** → Dispute filed by either party
6. **cancelled/expired** → Contract terminated

## Public Functions

### Contract Management

#### `create-service-contract`
Creates a new service contract between freelancer and client.

**Parameters:**
- `contract-id`: Unique identifier for the contract
- `freelancer-address`: Address of the freelancer
- `client-address`: Address of the client
- `project-start-date`: Project start timestamp
- `project-deadline`: Project completion deadline
- `contract-value`: Payment amount in microSTX
- `project-description`: Detailed project description

**Returns:** `(ok contract-id)` on success

#### `accept-contract`
Freelancer accepts contract terms and transitions to in-progress status.

**Parameters:**
- `contract-id`: Contract to accept

**Access:** Freelancer only

#### `submit-work-for-review`
Freelancer submits completed work for client review.

**Parameters:**
- `contract-id`: Contract to submit work for

**Access:** Freelancer only

#### `approve-work-and-release-payment`
Client approves work and releases payment to freelancer.

**Parameters:**
- `contract-id`: Contract to approve

**Access:** Client only

### Dispute Resolution

#### `file-contract-dispute`
File a dispute for unsatisfactory service or payment issues.

**Parameters:**
- `contract-id`: Contract in dispute
- `dispute-reason`: Description of the issue
- `evidence-hash`: Optional hash of supporting evidence

**Access:** Freelancer or Client

#### `resolve-dispute`
Admin resolves dispute with final decision.

**Parameters:**
- `contract-id`: Contract in dispute
- `resolution-decision`: Admin's resolution explanation
- `final-contract-status`: Final status for the contract

**Access:** Platform admin only

### Reputation System

#### `rate-freelancer-performance`
Submit rating for completed project.

**Parameters:**
- `freelancer-address`: Address of freelancer to rate
- `rating-score`: Rating from 1-5
- `specialization`: Freelancer's area of expertise

#### `verify-freelancer-credentials`
Verify freelancer credentials and expertise.

**Parameters:**
- `freelancer-address`: Address of freelancer to verify

**Access:** Platform admin only

### Platform Administration

#### `transfer-platform-ownership`
Transfer platform ownership to new administrator.

**Parameters:**
- `new-admin-address`: New admin's address

**Access:** Current admin only

#### `update-platform-status`
Toggle platform operational status for maintenance.

**Parameters:**
- `new-status`: Boolean operational status

**Access:** Platform admin only

#### `update-platform-fee`
Update platform fee structure.

**Parameters:**
- `new-fee-percentage`: New fee percentage (max 10%)

**Access:** Platform admin only

## Read-Only Functions

### Data Retrieval

- `get-contract-details(contract-id)`: Get contract information
- `get-freelancer-profile(freelancer-address)`: Get freelancer profile
- `get-client-profile(client-address)`: Get client profile
- `get-dispute-details(contract-id)`: Get dispute information
- `get-platform-admin()`: Get current admin address
- `get-platform-statistics()`: Get platform metrics
- `get-milestone-details(contract-id, milestone-id)`: Get milestone info

## Platform Configuration

### Default Settings
- **Minimum Contract Value**: 1 STX (1,000,000 microSTX)
- **Platform Fee**: 2.5% of contract value
- **Dispute Resolution Deadline**: ~1 week (1008 blocks)
- **Maximum Admin Fee**: 10%

### Error Codes
- `ERR-UNAUTHORIZED-ACCESS (u100)`: Access denied
- `ERR-CONTRACT-ALREADY-EXISTS (u101)`: Contract ID in use
- `ERR-CONTRACT-NOT-FOUND (u102)`: Contract doesn't exist
- `ERR-INVALID-STATUS-TRANSITION (u103)`: Invalid status change
- `ERR-INSUFFICIENT-PAYMENT-AMOUNT (u104)`: Payment too low
- `ERR-INVALID-ADDRESS-FORMAT (u105)`: Invalid principal address
- `ERR-INVALID-INPUT-PARAMETERS (u106)`: Invalid input data
- `ERR-PLATFORM-MAINTENANCE-MODE (u107)`: Platform offline
- `ERR-DEADLINE-BEFORE-START-DATE (u108)`: Invalid dates
- `ERR-RATING-OUT-OF-RANGE (u109)`: Rating must be 1-5

## Usage Examples

### Creating a Contract
```clarity
(contract-call? .freelance-hub create-service-contract
  u1                                    ;; contract-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 ;; freelancer
  'SP1WTA0XV7AX0BG3FVLJ67WVHVXAFKB3SXNZY7BN7 ;; client
  u1640995200                          ;; start date
  u1641600000                          ;; deadline
  u5000000                             ;; 5 STX value
  "Build responsive website"           ;; description
)
```

### Accepting a Contract
```clarity
(contract-call? .freelance-hub accept-contract u1)
```

### Filing a Dispute
```clarity
(contract-call? .freelance-hub file-contract-dispute
  u1                                    ;; contract-id
  "Work not delivered as specified"    ;; reason
  (some "QmX7Y8Z9...")                 ;; evidence hash
)
```

## Security Considerations

1. **Input Validation**: All inputs are validated for type, length, and format
2. **Access Control**: Functions restricted to appropriate user roles
3. **State Management**: Contract status transitions are enforced
4. **Economic Security**: Minimum contract values prevent spam
5. **Dispute Resolution**: Formal process with evidence tracking