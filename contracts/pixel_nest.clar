;; PixelNest - Pixel Art Creation and Storage Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-collection (err u104))
(define-constant err-transfer-failed (err u105))

;; Data Variables
(define-data-var next-artwork-id uint u0)
(define-data-var next-animation-id uint u0)
(define-data-var next-collection-id uint u0)

;; Define NFTs
(define-non-fungible-token pixel-art uint)
(define-non-fungible-token collection uint)

;; Data Maps
(define-map artworks
    uint 
    {
        owner: principal,
        width: uint,
        height: uint,
        pixels: (list 4096 uint),  ;; Max 64x64 pixels stored as colors
        created-at: uint,
        collection-id: (optional uint),
        transfer-restricted: bool
    }
)

;; New: Artwork Metadata Map
(define-map artwork-metadata
    uint
    {
        title: (optional (string-ascii 64)),
        description: (optional (string-ascii 256)),
        tags: (list 5 (string-ascii 32))
    }
)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
    uint
    {
        event-type: (string-ascii 32),
        artwork-id: uint,
        actor: principal,
        timestamp: uint
    }
)

;; Helper function to emit events
(define-private (emit-event (event-type (string-ascii 32)) (artwork-id uint))
    (let
        ((event-id (+ (var-get last-event-id) u1)))
        (var-set last-event-id event-id)
        (map-set events event-id {
            event-type: event-type,
            artwork-id: artwork-id,
            actor: tx-sender,
            timestamp: block-height
        })
        (ok event-id)
    )
)

;; Transfer artwork NFT with restrictions check and event emission
(define-public (transfer-artwork (artwork-id uint) (recipient principal))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) (err u101)))
        )
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        (asserts! (not (get transfer-restricted artwork)) err-transfer-failed)
        (try! (nft-transfer? pixel-art artwork-id tx-sender recipient))
        (map-set artworks artwork-id (merge artwork { 
            owner: recipient,
            collection-id: none
        }))
        (try! (emit-event "transfer" artwork-id))
        (ok true)
    )
)

;; Enhanced function to toggle transfer restrictions with event emission
(define-public (set-artwork-transfer-restriction (artwork-id uint) (restricted bool))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
        )
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        (map-set artworks artwork-id (merge artwork {
            transfer-restricted: restricted
        }))
        (try! (emit-event (if restricted "restrict_transfer" "unrestrict_transfer") artwork-id))
        (ok true)
    )
)

;; New: Set artwork metadata
(define-public (set-artwork-metadata 
    (artwork-id uint)
    (title (optional (string-ascii 64)))
    (description (optional (string-ascii 256)))
    (tags (list 5 (string-ascii 32))))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
        )
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        (map-set artwork-metadata artwork-id {
            title: title,
            description: description,
            tags: tags
        })
        (try! (emit-event "metadata_update" artwork-id))
        (ok true)
    )
)
