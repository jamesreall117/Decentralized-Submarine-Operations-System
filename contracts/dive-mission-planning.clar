;; dive-mission-planning.clar

;; Constants
(define-constant MAX-DEPTH u100)  ;; Maximum allowed depth in meters
(define-constant MAX-DURATION u60) ;; Maximum allowed duration in minutes

;; Data Structures
(define-map dive-missions
  { mission-id: uint }
  { target-depth: uint, planned-duration: uint, success: bool }
)

;; Public Functions

;; Submit a dive mission plan
(define-public (plan-dive-mission (mission-id uint) (target-depth uint) (planned-duration uint))
  (begin
    (asserts! (<= target-depth MAX-DEPTH) err-depth-exceeds-max)
    (asserts! (<= planned-duration MAX-DURATION) err-duration-exceeds-max)

    (map-insert dive-missions
      { mission-id: mission-id }
      { target-depth: target-depth, planned-duration: planned-duration, success: false }
    )

    (ok true)
  )
)

;; Mark a dive mission as successful
(define-public (mark-mission-success (mission-id uint))
  (begin
    (map-set dive-missions
      { mission-id: mission-id }
      { target-depth: (get target-depth (unwrap! (map-get? dive-missions { mission-id: mission-id }) err-mission-not-found)),
        planned-duration: (get planned-duration (unwrap! (map-get? dive-missions { mission-id: mission-id }) err-mission-not-found)),
        success: true }
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get dive mission details
(define-read-only (get-dive-mission (mission-id uint))
  (match (map-get? dive-missions { mission-id: mission-id })
    mission (ok mission)
    (err err-mission-not-found)
  )
)

;; Error Codes
(define-constant err-depth-exceeds-max (err u1000))
(define-constant err-duration-exceeds-max (err u1001))
(define-constant err-mission-not-found (err u1002))
