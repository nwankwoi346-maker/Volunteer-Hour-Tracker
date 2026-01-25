(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-hours (err u103))
(define-constant err-not-verified (err u104))
(define-constant err-already-verified (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-milestone-not-reached (err u107))
(define-constant err-milestone-already-claimed (err u108))

(define-constant milestone-bronze u25)
(define-constant milestone-silver u50)
(define-constant milestone-gold u100)
(define-constant milestone-platinum u250)
(define-constant milestone-diamond u500)

(define-data-var next-volunteer-id uint u1)
(define-data-var next-session-id uint u1)
(define-data-var total-hours-tracked uint u0)
(define-data-var reward-rate uint u10)

(define-map volunteers
  { volunteer-id: uint }
  {
    principal: principal,
    name: (string-ascii 50),
    email: (string-ascii 100),
    total-hours: uint,
    verified-hours: uint,
    reward-balance: uint,
    registration-block: uint,
    active: bool
  }
)

(define-map volunteer-principals
  { principal: principal }
  { volunteer-id: uint }
)

(define-map volunteer-sessions
  { session-id: uint }
  {
    volunteer-id: uint,
    organization: (string-ascii 100),
    activity: (string-ascii 200),
    hours: uint,
    start-block: uint,
    end-block: uint,
    verified: bool,
    verifier: (optional principal),
    verification-block: (optional uint)
  }
)

(define-map organization-verifiers
  { organization: (string-ascii 100) }
  { verifier: principal }
)

(define-map volunteer-session-ids
  { volunteer-id: uint, session-index: uint }
  { session-id: uint }
)

(define-map volunteer-session-counts
  { volunteer-id: uint }
  { count: uint }
)

(define-map volunteer-milestones
  { volunteer-id: uint }
  {
    bronze-claimed: bool,
    silver-claimed: bool,
    gold-claimed: bool,
    platinum-claimed: bool,
    diamond-claimed: bool,
    total-milestones: uint
  }
)

(define-public (register-volunteer (name (string-ascii 50)) (email (string-ascii 100)))
  (let
    (
      (volunteer-id (var-get next-volunteer-id))
    )
    (asserts! (is-none (map-get? volunteer-principals {principal: tx-sender})) err-already-exists)
    (map-set volunteers
      {volunteer-id: volunteer-id}
      {
        principal: tx-sender,
        name: name,
        email: email,
        total-hours: u0,
        verified-hours: u0,
        reward-balance: u0,
        registration-block: u0,
        active: true
      }
    )
    (map-set volunteer-principals {principal: tx-sender} {volunteer-id: volunteer-id})
    (map-set volunteer-session-counts {volunteer-id: volunteer-id} {count: u0})
    (map-set volunteer-milestones
      {volunteer-id: volunteer-id}
      {
        bronze-claimed: false,
        silver-claimed: false,
        gold-claimed: false,
        platinum-claimed: false,
        diamond-claimed: false,
        total-milestones: u0
      }
    )
    (var-set next-volunteer-id (+ volunteer-id u1))
    (ok volunteer-id)
  )
)

(define-public (log-hours (organization (string-ascii 100)) (activity (string-ascii 200)) (hours uint))
  (let
    (
      (volunteer-lookup (map-get? volunteer-principals {principal: tx-sender}))
      (session-id (var-get next-session-id))
    )
    (asserts! (> hours u0) err-invalid-hours)
    (asserts! (<= hours u24) err-invalid-hours)
    (match volunteer-lookup volunteer-data
      (let
        (
          (volunteer-id (get volunteer-id volunteer-data))
          (volunteer-info (unwrap! (map-get? volunteers {volunteer-id: volunteer-id}) err-not-found))
          (session-count (default-to u0 (get count (map-get? volunteer-session-counts {volunteer-id: volunteer-id}))))
        )
        (asserts! (get active volunteer-info) err-not-found)
        (map-set volunteer-sessions
          {session-id: session-id}
          {
            volunteer-id: volunteer-id,
            organization: organization,
            activity: activity,
            hours: hours,
            start-block: u0,
            end-block: u0,
            verified: false,
            verifier: none,
            verification-block: none
          }
        )
        (map-set volunteer-session-ids
          {volunteer-id: volunteer-id, session-index: session-count}
          {session-id: session-id}
        )
        (map-set volunteer-session-counts
          {volunteer-id: volunteer-id}
          {count: (+ session-count u1)}
        )
        (map-set volunteers
          {volunteer-id: volunteer-id}
          (merge volunteer-info {total-hours: (+ (get total-hours volunteer-info) hours)})
        )
        (var-set next-session-id (+ session-id u1))
        (var-set total-hours-tracked (+ (var-get total-hours-tracked) hours))
        (ok session-id)
      )
      err-not-found
    )
  )
)

(define-public (register-organization-verifier (organization (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set organization-verifiers {organization: organization} {verifier: tx-sender})
    (ok true)
  )
)

(define-public (verify-session (session-id uint))
  (let
    (
      (session-info (unwrap! (map-get? volunteer-sessions {session-id: session-id}) err-not-found))
      (volunteer-id (get volunteer-id session-info))
      (volunteer-info (unwrap! (map-get? volunteers {volunteer-id: volunteer-id}) err-not-found))
      (hours (get hours session-info))
      (organization (get organization session-info))
      (verifier-info (map-get? organization-verifiers {organization: organization}))
    )
    (asserts! (not (get verified session-info)) err-already-verified)
    (asserts! 
      (or 
        (is-eq tx-sender contract-owner)
        (match verifier-info verifier-data
          (is-eq tx-sender (get verifier verifier-data))
          false
        )
      ) 
      err-owner-only
    )
    (map-set volunteer-sessions
      {session-id: session-id}
      (merge session-info {
        verified: true,
        verifier: (some tx-sender),
        verification-block: (some u0)
      })
    )
    (let
      (
        (new-verified-hours (+ (get verified-hours volunteer-info) hours))
        (reward-earned (* hours (var-get reward-rate)))
        (new-reward-balance (+ (get reward-balance volunteer-info) reward-earned))
      )
      (map-set volunteers
        {volunteer-id: volunteer-id}
        (merge volunteer-info {
          verified-hours: new-verified-hours,
          reward-balance: new-reward-balance
        })
      )
      (ok true)
    )
  )
)

(define-public (claim-rewards (amount uint))
  (let
    (
      (volunteer-lookup (map-get? volunteer-principals {principal: tx-sender}))
    )
    (match volunteer-lookup volunteer-data
      (let
        (
          (volunteer-id (get volunteer-id volunteer-data))
          (volunteer-info (unwrap! (map-get? volunteers {volunteer-id: volunteer-id}) err-not-found))
          (current-balance (get reward-balance volunteer-info))
        )
        (asserts! (>= current-balance amount) err-insufficient-balance)
        (map-set volunteers
          {volunteer-id: volunteer-id}
          (merge volunteer-info {reward-balance: (- current-balance amount)})
        )
        (ok amount)
      )
      err-not-found
    )
  )
)

(define-public (update-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set reward-rate new-rate)
    (ok true)
  )
)

(define-public (deactivate-volunteer (volunteer-id uint))
  (let
    (
      (volunteer-info (unwrap! (map-get? volunteers {volunteer-id: volunteer-id}) err-not-found))
    )
    (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get principal volunteer-info))) err-owner-only)
    (map-set volunteers
      {volunteer-id: volunteer-id}
      (merge volunteer-info {active: false})
    )
    (ok true)
  )
)

(define-read-only (get-volunteer-info (volunteer-id uint))
  (map-get? volunteers {volunteer-id: volunteer-id})
)

(define-read-only (get-volunteer-by-principal (principal-addr principal))
  (match (map-get? volunteer-principals {principal: principal-addr})
    volunteer-data (map-get? volunteers {volunteer-id: (get volunteer-id volunteer-data)})
    none
  )
)

(define-read-only (get-session-info (session-id uint))
  (map-get? volunteer-sessions {session-id: session-id})
)

(define-read-only (get-volunteer-session (volunteer-id uint) (session-index uint))
  (match (map-get? volunteer-session-ids {volunteer-id: volunteer-id, session-index: session-index})
    session-data (map-get? volunteer-sessions {session-id: (get session-id session-data)})
    none
  )
)

(define-read-only (get-volunteer-session-count (volunteer-id uint))
  (default-to u0 (get count (map-get? volunteer-session-counts {volunteer-id: volunteer-id})))
)

(define-read-only (get-total-hours)
  (var-get total-hours-tracked)
)

(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

(define-read-only (get-contract-stats)
  {
    total-volunteers: (- (var-get next-volunteer-id) u1),
    total-sessions: (- (var-get next-session-id) u1),
    total-hours: (var-get total-hours-tracked),
    reward-rate: (var-get reward-rate)
  }
)

(define-read-only (is-organization-verifier (organization (string-ascii 100)) (principal-addr principal))
  (match (map-get? organization-verifiers {organization: organization})
    verifier-data (is-eq principal-addr (get verifier verifier-data))
    false
  )
)

(define-public (claim-milestone (milestone-type (string-ascii 10)))
  (let
    (
      (volunteer-lookup (map-get? volunteer-principals {principal: tx-sender}))
    )
    (match volunteer-lookup volunteer-data
      (let
        (
          (volunteer-id (get volunteer-id volunteer-data))
          (volunteer-info (unwrap! (map-get? volunteers {volunteer-id: volunteer-id}) err-not-found))
          (milestones (unwrap! (map-get? volunteer-milestones {volunteer-id: volunteer-id}) err-not-found))
          (verified-hours (get verified-hours volunteer-info))
        )
        (if (is-eq milestone-type "bronze")
          (begin
            (asserts! (>= verified-hours milestone-bronze) err-milestone-not-reached)
            (asserts! (not (get bronze-claimed milestones)) err-milestone-already-claimed)
            (map-set volunteer-milestones
              {volunteer-id: volunteer-id}
              (merge milestones {bronze-claimed: true, total-milestones: (+ (get total-milestones milestones) u1)})
            )
            (ok "bronze")
          )
          (if (is-eq milestone-type "silver")
            (begin
              (asserts! (>= verified-hours milestone-silver) err-milestone-not-reached)
              (asserts! (not (get silver-claimed milestones)) err-milestone-already-claimed)
              (map-set volunteer-milestones
                {volunteer-id: volunteer-id}
                (merge milestones {silver-claimed: true, total-milestones: (+ (get total-milestones milestones) u1)})
              )
              (ok "silver")
            )
            (if (is-eq milestone-type "gold")
              (begin
                (asserts! (>= verified-hours milestone-gold) err-milestone-not-reached)
                (asserts! (not (get gold-claimed milestones)) err-milestone-already-claimed)
                (map-set volunteer-milestones
                  {volunteer-id: volunteer-id}
                  (merge milestones {gold-claimed: true, total-milestones: (+ (get total-milestones milestones) u1)})
                )
                (ok "gold")
              )
              (if (is-eq milestone-type "platinum")
                (begin
                  (asserts! (>= verified-hours milestone-platinum) err-milestone-not-reached)
                  (asserts! (not (get platinum-claimed milestones)) err-milestone-already-claimed)
                  (map-set volunteer-milestones
                    {volunteer-id: volunteer-id}
                    (merge milestones {platinum-claimed: true, total-milestones: (+ (get total-milestones milestones) u1)})
                  )
                  (ok "platinum")
                )
                (if (is-eq milestone-type "diamond")
                  (begin
                    (asserts! (>= verified-hours milestone-diamond) err-milestone-not-reached)
                    (asserts! (not (get diamond-claimed milestones)) err-milestone-already-claimed)
                    (map-set volunteer-milestones
                      {volunteer-id: volunteer-id}
                      (merge milestones {diamond-claimed: true, total-milestones: (+ (get total-milestones milestones) u1)})
                    )
                    (ok "diamond")
                  )
                  err-not-found
                )
              )
            )
          )
        )
      )
      err-not-found
    )
  )
)

(define-read-only (get-volunteer-milestones (volunteer-id uint))
  (map-get? volunteer-milestones {volunteer-id: volunteer-id})
)

(define-read-only (get-milestone-thresholds)
  {
    bronze: milestone-bronze,
    silver: milestone-silver,
    gold: milestone-gold,
    platinum: milestone-platinum,
    diamond: milestone-diamond
  }
)

(define-read-only (get-available-milestones (volunteer-id uint))
  (match (map-get? volunteers {volunteer-id: volunteer-id})
    volunteer-info
    (let
      (
        (verified-hours (get verified-hours volunteer-info))
        (milestones (default-to
          {bronze-claimed: false, silver-claimed: false, gold-claimed: false, platinum-claimed: false, diamond-claimed: false, total-milestones: u0}
          (map-get? volunteer-milestones {volunteer-id: volunteer-id})
        ))
      )
      (some {
        bronze-available: (and (>= verified-hours milestone-bronze) (not (get bronze-claimed milestones))),
        silver-available: (and (>= verified-hours milestone-silver) (not (get silver-claimed milestones))),
        gold-available: (and (>= verified-hours milestone-gold) (not (get gold-claimed milestones))),
        platinum-available: (and (>= verified-hours milestone-platinum) (not (get platinum-claimed milestones))),
        diamond-available: (and (>= verified-hours milestone-diamond) (not (get diamond-claimed milestones)))
      })
    )
    none
  )
)
