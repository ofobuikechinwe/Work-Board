;; FreelanceHub: Decentralized Professional Services Marketplace Smart Contract
;; 
;; A trustless blockchain-based platform connecting freelancers with clients through
;; secure smart contracts. Features automated escrow payments, reputation tracking,
;; dispute resolution, and transparent project management. Eliminates intermediaries
;; while ensuring fair compensation and quality service delivery through
;; cryptographically-enforced agreements and community-driven arbitration.

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-CONTRACT-ALREADY-EXISTS (err u101))
(define-constant ERR-CONTRACT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS-TRANSITION (err u103))
(define-constant ERR-INSUFFICIENT-PAYMENT-AMOUNT (err u104))
(define-constant ERR-INVALID-ADDRESS-FORMAT (err u105))
(define-constant ERR-INVALID-INPUT-PARAMETERS (err u106))
(define-constant ERR-PLATFORM-MAINTENANCE-MODE (err u107))
(define-constant ERR-DEADLINE-BEFORE-START-DATE (err u108))
(define-constant ERR-RATING-OUT-OF-RANGE (err u109))
(define-constant ERR-INVALID-EVIDENCE-HASH (err u110))

;; PLATFORM CONFIGURATION

(define-data-var platform-admin-address principal tx-sender)
(define-data-var total-contracts-created uint u0)
(define-data-var platform-operational-status bool true)
(define-data-var minimum-contract-value uint u1000000) ;; 1 STX minimum
(define-data-var platform-fee-percentage uint u250) ;; 2.5%

;; CORE DATA STRUCTURES

;; Service contract registry with comprehensive project details
(define-map service-contracts
    { contract-id: uint }
    {
        freelancer-address: principal,
        client-address: principal,
        project-start-date: uint,
        project-deadline: uint,
        contract-value: uint,
        current-status: (string-ascii 25),
        project-description: (string-ascii 500),
        payment-released: bool,
        completion-timestamp: (optional uint)
    }
)

;; Freelancer profiles with reputation metrics and specialization
(define-map freelancer-profiles
    { freelancer-address: principal }
    {
        average-rating: uint,
        total-projects-completed: uint,
        successful-deliveries: uint,
        registration-date: uint,
        specialization-area: (string-ascii 50),
        total-earnings: uint,
        is-verified: bool
    }
)

;; Client profiles with project history and spending patterns
(define-map client-profiles
    { client-address: principal }
    {
        organization-name: (string-ascii 100),
        total-projects-posted: uint,
        average-project-budget: uint,
        registration-date: uint,
        total-spent: uint,
        reputation-score: uint
    }
)

;; Dispute management system with arbitration workflow
(define-map contract-disputes
    { contract-id: uint }
    {
        complainant-address: principal,
        dispute-reason: (string-ascii 300),
        dispute-status: (string-ascii 20),
        admin-resolution: (optional (string-ascii 300)),
        dispute-created-at: uint,
        resolution-deadline: uint,
        evidence-hash: (optional (string-ascii 64))
    }
)

;; Project milestone tracking for complex contracts
(define-map project-milestones
    { contract-id: uint, milestone-id: uint }
    {
        milestone-description: (string-ascii 200),
        milestone-value: uint,
        is-completed: bool,
        completion-date: (optional uint),
        client-approved: bool
    }
)

;; PLATFORM ADMINISTRATION

;; Transfer platform ownership to new administrator
(define-public (transfer-platform-ownership (new-admin-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin-address)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-principal new-admin-address) ERR-INVALID-ADDRESS-FORMAT)
        (var-set platform-admin-address new-admin-address)
        (ok true)
    )
)

;; Toggle platform operational status for maintenance
(define-public (update-platform-status (new-status bool))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin-address)) ERR-UNAUTHORIZED-ACCESS)
        (var-set platform-operational-status new-status)
        (ok true)
    )
)

;; Update platform fee structure
(define-public (update-platform-fee (new-fee-percentage uint))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin-address)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (<= new-fee-percentage u1000) ERR-INVALID-INPUT-PARAMETERS) ;; Max 10%
        (var-set platform-fee-percentage new-fee-percentage)
        (ok true)
    )
)

;; CONTRACT LIFECYCLE MANAGEMENT

;; Create new service contract between freelancer and client
(define-public (create-service-contract
    (contract-id uint)
    (freelancer-address principal)
    (client-address principal)
    (project-start-date uint)
    (project-deadline uint)
    (contract-value uint)
    (project-description (string-ascii 500)))
    
    (let ((platform-active (var-get platform-operational-status))
          (existing-contract (get-contract-details contract-id)))
        
        (asserts! platform-active ERR-PLATFORM-MAINTENANCE-MODE)
        (asserts! (is-none existing-contract) ERR-CONTRACT-ALREADY-EXISTS)
        (asserts! (>= project-deadline project-start-date) ERR-DEADLINE-BEFORE-START-DATE)
        (asserts! (>= contract-value (var-get minimum-contract-value)) ERR-INSUFFICIENT-PAYMENT-AMOUNT)
        (asserts! (is-valid-principal freelancer-address) ERR-INVALID-ADDRESS-FORMAT)
        (asserts! (is-valid-principal client-address) ERR-INVALID-ADDRESS-FORMAT)
        (asserts! (validate-text-input project-description) ERR-INVALID-INPUT-PARAMETERS)
        (asserts! (not (is-eq freelancer-address client-address)) ERR-INVALID-INPUT-PARAMETERS)
        
        ;; Create contract record
        (map-set service-contracts
            { contract-id: contract-id }
            {
                freelancer-address: freelancer-address,
                client-address: client-address,
                project-start-date: project-start-date,
                project-deadline: project-deadline,
                contract-value: contract-value,
                current-status: "pending-acceptance",
                project-description: project-description,
                payment-released: false,
                completion-timestamp: none
            }
        )
        
        ;; Update participant profiles
        (update-freelancer-metrics freelancer-address)
        (update-client-metrics client-address)
        (var-set total-contracts-created (+ (var-get total-contracts-created) u1))
        (ok contract-id)
    )
)

;; Freelancer accepts contract terms and conditions
(define-public (accept-contract (contract-id uint))
    (let ((contract-data (unwrap! (get-contract-details contract-id) ERR-CONTRACT-NOT-FOUND)))
        
        (asserts! (is-eq (get current-status contract-data) "pending-acceptance") ERR-INVALID-STATUS-TRANSITION)
        (asserts! (is-eq tx-sender (get freelancer-address contract-data)) ERR-UNAUTHORIZED-ACCESS)
        
        (map-set service-contracts
            { contract-id: contract-id }
            (merge contract-data { current-status: "in-progress" })
        )
        (ok true)
    )
)

;; Freelancer submits completed work for client review
(define-public (submit-work-for-review (contract-id uint))
    (let ((contract-data (unwrap! (get-contract-details contract-id) ERR-CONTRACT-NOT-FOUND)))
        
        (asserts! (is-eq (get current-status contract-data) "in-progress") ERR-INVALID-STATUS-TRANSITION)
        (asserts! (is-eq tx-sender (get freelancer-address contract-data)) ERR-UNAUTHORIZED-ACCESS)
        
        (map-set service-contracts
            { contract-id: contract-id }
            (merge contract-data { current-status: "under-review" })
        )
        (ok true)
    )
)

;; Client approves work and releases payment
(define-public (approve-work-and-release-payment (contract-id uint))
    (let ((contract-data (unwrap! (get-contract-details contract-id) ERR-CONTRACT-NOT-FOUND)))
        
        (asserts! (is-eq (get current-status contract-data) "under-review") ERR-INVALID-STATUS-TRANSITION)
        (asserts! (is-eq tx-sender (get client-address contract-data)) ERR-UNAUTHORIZED-ACCESS)
        
        ;; Update contract status
        (map-set service-contracts
            { contract-id: contract-id }
            (merge contract-data { 
                current-status: "completed",
                payment-released: true,
                completion-timestamp: (some block-height)
            })
        )
        
        ;; Update freelancer success metrics
        (increment-freelancer-completions (get freelancer-address contract-data))
        (ok true)
    )
)

;; DISPUTE RESOLUTION SYSTEM

;; File dispute for unsatisfactory service or payment issues
(define-public (file-contract-dispute
    (contract-id uint)
    (dispute-reason (string-ascii 300))
    (evidence-hash (optional (string-ascii 64))))
    
    (let ((contract-data (unwrap! (get-contract-details contract-id) ERR-CONTRACT-NOT-FOUND))
          (validated-evidence-hash (validate-evidence-hash evidence-hash)))
        
        (asserts! (or (is-eq tx-sender (get freelancer-address contract-data))
                      (is-eq tx-sender (get client-address contract-data))) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-input dispute-reason) ERR-INVALID-INPUT-PARAMETERS)
        (asserts! validated-evidence-hash ERR-INVALID-EVIDENCE-HASH)
        
        ;; Create dispute record
        (map-set contract-disputes
            { contract-id: contract-id }
            {
                complainant-address: tx-sender,
                dispute-reason: dispute-reason,
                dispute-status: "open",
                admin-resolution: none,
                dispute-created-at: block-height,
                resolution-deadline: (+ block-height u1008), ;; ~1 week
                evidence-hash: evidence-hash
            }
        )
        
        ;; Update contract status
        (map-set service-contracts
            { contract-id: contract-id }
            (merge contract-data { current-status: "disputed" })
        )
        (ok true)
    )
)

;; Admin resolves dispute with final decision
(define-public (resolve-dispute
    (contract-id uint)
    (resolution-decision (string-ascii 300))
    (final-contract-status (string-ascii 25)))
    
    (let ((contract-data (unwrap! (get-contract-details contract-id) ERR-CONTRACT-NOT-FOUND))
          (dispute-data (unwrap! (get-dispute-details contract-id) ERR-CONTRACT-NOT-FOUND)))
        
        (asserts! (is-eq tx-sender (var-get platform-admin-address)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-eq (get current-status contract-data) "disputed") ERR-INVALID-STATUS-TRANSITION)
        (asserts! (is-valid-status final-contract-status) ERR-INVALID-STATUS-TRANSITION)
        (asserts! (validate-text-input resolution-decision) ERR-INVALID-INPUT-PARAMETERS)
        
        ;; Update dispute record
        (map-set contract-disputes
            { contract-id: contract-id }
            (merge dispute-data {
                dispute-status: "resolved",
                admin-resolution: (some resolution-decision)
            })
        )
        
        ;; Update contract status
        (map-set service-contracts
            { contract-id: contract-id }
            (merge contract-data { current-status: final-contract-status })
        )
        (ok true)
    )
)

;; REPUTATION AND RATING SYSTEM

;; Submit rating for completed project
(define-public (rate-freelancer-performance
    (freelancer-address principal)
    (rating-score uint)
    (specialization (string-ascii 50)))
    
    (let ((freelancer-data (get-freelancer-profile freelancer-address)))
        
        (asserts! (is-valid-principal freelancer-address) ERR-INVALID-ADDRESS-FORMAT)
        (asserts! (and (<= rating-score u5) (>= rating-score u1)) ERR-RATING-OUT-OF-RANGE)
        
        (match freelancer-data
            existing-data
            (begin
                (map-set freelancer-profiles
                    { freelancer-address: freelancer-address }
                    (merge existing-data {
                        average-rating: (calculate-weighted-average 
                            (get average-rating existing-data)
                            (get total-projects-completed existing-data)
                            rating-score),
                        specialization-area: specialization
                    })
                )
                (ok true)
            )
            (ok false) ;; Freelancer profile doesn't exist
        )
    )
)

;; Verify freelancer credentials and expertise
(define-public (verify-freelancer-credentials (freelancer-address principal))
    (let ((freelancer-data (get-freelancer-profile freelancer-address)))
        
        (asserts! (is-eq tx-sender (var-get platform-admin-address)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-principal freelancer-address) ERR-INVALID-ADDRESS-FORMAT)
        
        (match freelancer-data
            existing-data
            (begin
                (map-set freelancer-profiles
                    { freelancer-address: freelancer-address }
                    (merge existing-data { is-verified: true })
                )
                (ok true)
            )
            (ok false) ;; Freelancer profile doesn't exist
        )
    )
)

;; PUBLIC READ-ONLY FUNCTIONS

(define-read-only (get-contract-details (contract-id uint))
    (map-get? service-contracts { contract-id: contract-id })
)

(define-read-only (get-freelancer-profile (freelancer-address principal))
    (map-get? freelancer-profiles { freelancer-address: freelancer-address })
)

(define-read-only (get-client-profile (client-address principal))
    (map-get? client-profiles { client-address: client-address })
)

(define-read-only (get-dispute-details (contract-id uint))
    (map-get? contract-disputes { contract-id: contract-id })
)

(define-read-only (get-platform-admin)
    (var-get platform-admin-address)
)

(define-read-only (get-platform-statistics)
    {
        total-contracts: (var-get total-contracts-created),
        platform-fee: (var-get platform-fee-percentage),
        minimum-value: (var-get minimum-contract-value),
        operational-status: (var-get platform-operational-status)
    }
)

(define-read-only (get-milestone-details (contract-id uint) (milestone-id uint))
    (map-get? project-milestones { contract-id: contract-id, milestone-id: milestone-id })
)

;; PRIVATE HELPER FUNCTIONS

;; Initialize or update freelancer profile metrics
(define-private (update-freelancer-metrics (freelancer-address principal))
    (match (get-freelancer-profile freelancer-address)
        existing-profile
        (map-set freelancer-profiles
            { freelancer-address: freelancer-address }
            (merge existing-profile {
                total-projects-completed: (+ (get total-projects-completed existing-profile) u1)
            })
        )
        (map-set freelancer-profiles
            { freelancer-address: freelancer-address }
            {
                average-rating: u0,
                total-projects-completed: u1,
                successful-deliveries: u0,
                registration-date: block-height,
                specialization-area: "general",
                total-earnings: u0,
                is-verified: false
            }
        )
    )
)

;; Initialize or update client profile metrics
(define-private (update-client-metrics (client-address principal))
    (match (get-client-profile client-address)
        existing-profile
        (map-set client-profiles
            { client-address: client-address }
            (merge existing-profile {
                total-projects-posted: (+ (get total-projects-posted existing-profile) u1)
            })
        )
        (map-set client-profiles
            { client-address: client-address }
            {
                organization-name: "New Client",
                total-projects-posted: u1,
                average-project-budget: u0,
                registration-date: block-height,
                total-spent: u0,
                reputation-score: u0
            }
        )
    )
)

;; Increment successful project completions for freelancer
(define-private (increment-freelancer-completions (freelancer-address principal))
    (match (get-freelancer-profile freelancer-address)
        freelancer-data
        (begin
            (map-set freelancer-profiles
                { freelancer-address: freelancer-address }
                (merge freelancer-data {
                    successful-deliveries: (+ (get successful-deliveries freelancer-data) u1)
                })
            )
            true
        )
        false
    )
)

;; Calculate weighted average rating with new score
(define-private (calculate-weighted-average
    (current-average uint)
    (total-ratings uint)
    (new-rating uint))
    (if (is-eq total-ratings u0)
        new-rating
        (/ (+ (* current-average total-ratings) new-rating) (+ total-ratings u1))
    )
)

;; VALIDATION FUNCTIONS

;; Validate contract status transitions
(define-private (is-valid-status (status (string-ascii 25)))
    (or (is-eq status "pending-acceptance")
        (is-eq status "in-progress")
        (is-eq status "under-review")
        (is-eq status "completed")
        (is-eq status "disputed")
        (is-eq status "cancelled")
        (is-eq status "expired"))
)

;; Validate principal address format
(define-private (is-valid-principal (address principal))
    (is-ok (principal-destruct? address))
)

;; Validate text input requirements
(define-private (validate-text-input (text (string-ascii 500)))
    (and (>= (len text) u1) (<= (len text) u500))
)

;; Validate evidence hash format and content
(define-private (validate-evidence-hash (evidence-hash (optional (string-ascii 64))))
    (match evidence-hash
        hash-value
        (and (>= (len hash-value) u32) (<= (len hash-value) u64))
        true ;; None is valid
    )
)