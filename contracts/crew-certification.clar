;; Crew Certification Contract
;; Validates submarine operator qualifications

(define-constant contract-owner tx-sender)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-CREW-EXISTS (err u201))
(define-constant ERR-CREW-NOT-FOUND (err u202))
(define-constant ERR-INVALID-LEVEL (err u203))
(define-constant ERR-CERTIFICATION-EXPIRED (err u204))
(define-constant ERR-INVALID-RATING (err u205))

;; Constants
(define-constant MAX-CERTIFICATION-LEVEL u5)
(define-constant CERTIFICATION-DURATION u52560) ;; ~1 year in blocks

;; Data variables
(define-data-var certification-counter uint u0)

;; Data maps
(define-map crew-members
  principal
  {
    name: (string-ascii 100),
    certification-level: uint,
    specializations: (list 10 (string-ascii 50)),
    certification-date: uint,
    expiry-date: uint,
    total-dives: uint,
    safety-rating: uint
  }
)

(define-map training-records
  principal
  (list 20 {
    course-name: (string-ascii 100),
    completion-date: uint,
    instructor: principal,
    score: uint
  })
)

(define-map certifiers (principal bool)

;; Public functions

(define-public (register-crew-member
  (member principal)
  (name (string-ascii 100))
  (certification-level uint)
  (specializations (list 10 (string-ascii 50))))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? crew-members member)) ERR-CREW-EXISTS)
    (asserts! (> certification-level u0) ERR-INVALID-LEVEL)
    (asserts! (<= certification-level MAX-CERTIFICATION-LEVEL) ERR-INVALID-LEVEL)

    (map-set crew-members member
      {
        name: name,
        certification-level: certification-level,
        specializations: specializations,
        certification-date: block-height,
        expiry-date: (+ block-height CERTIFICATION-DURATION),
        total-dives: u0,
        safety-rating: u5
      })
    (ok true)))

(define-public (add-certifier (certifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (map-set certifiers certifier true)
    (ok true)))

(define-public (update-certification-level
  (member principal)
  (new-level uint))
  (let ((crew-data (unwrap! (map-get? crew-members member) ERR-CREW-NOT-FOUND)))
    (asserts! (is-some (map-get? certifiers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-level u0) ERR-INVALID-LEVEL)
    (asserts! (<= new-level MAX-CERTIFICATION-LEVEL) ERR-INVALID-LEVEL)

    (map-set crew-members member
      (merge crew-data {
        certification-level: new-level,
        certification-date: block-height,
        expiry-date: (+ block-height CERTIFICATION-DURATION)
      }))
    (ok true)))

(define-public (add-training-record
  (member principal)
  (course-name (string-ascii 100))
  (score uint))
  (let ((current-records (default-to (list) (map-get? training-records member))))
    (asserts! (is-some (map-get? certifiers tx-sender)) ERR-NOT-AUTHORIZED)

    (let ((new-record {
      course-name: course-name,
      completion-date: block-height,
      instructor: tx-sender,
      score: score
    }))
    (map-set training-records member (unwrap! (as-max-len? (append current-records new-record) u20) ERR-CREW-NOT-FOUND))
    (ok true))))

(define-public (increment-dive-count (member principal))
  (let ((crew-data (unwrap! (map-get? crew-members member) ERR-CREW-NOT-FOUND)))
    (asserts! (is-eq tx-sender member) ERR-NOT-AUTHORIZED)

    (map-set crew-members member
      (merge crew-data {total-dives: (+ (get total-dives crew-data) u1)}))
    (ok true)))

(define-public (update-safety-rating
  (member principal)
  (rating uint))
  (let ((crew-data (unwrap! (map-get? crew-members member) ERR-CREW-NOT-FOUND)))
    (asserts! (is-some (map-get? certifiers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> rating u0) ERR-INVALID-RATING)
    (<= rating u5)

    (map-set crew-members member
      (merge crew-data {safety-rating: rating}))
    (ok true)))

;; Read-only functions

(define-read-only (get-crew-member (member principal))
  (map-get? crew-members member))

(define-read-only (get-training-records (member principal))
  (map-get? training-records member))

(define-read-only (is-certification-valid (member principal))
  (match (map-get? crew-members member)
    crew-data (< block-height (get expiry-date crew-data))
    false))

(define-read-only (get-certification-level (member principal))
  (match (map-get? crew-members member)
    crew-data (some (get certification-level crew-data))
    none))

(define-read-only (is-certifier (principal principal))
  (default-to false (map-get? certifiers principal)))
