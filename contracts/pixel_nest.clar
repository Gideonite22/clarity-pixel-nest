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

;; Rest of contract remains unchanged...

;; Transfer artwork NFT with restrictions check
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
        (ok true)
    )
)

;; New function to toggle transfer restrictions
(define-public (set-artwork-transfer-restriction (artwork-id uint) (restricted bool))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
        )
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        (map-set artworks artwork-id (merge artwork {
            transfer-restricted: restricted
        }))
        (ok true)
    )
)
