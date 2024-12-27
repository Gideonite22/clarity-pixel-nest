;; PixelNest - Pixel Art Creation and Storage Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var next-artwork-id uint u0)
(define-data-var next-animation-id uint u0)

;; Define NFT
(define-non-fungible-token pixel-art uint)

;; Data Maps
(define-map artworks
    uint 
    {
        owner: principal,
        width: uint,
        height: uint,
        pixels: (list 4096 uint),  ;; Max 64x64 pixels stored as colors
        created-at: uint
    }
)

(define-map animations
    uint
    {
        owner: principal,
        frame-ids: (list 32 uint),  ;; References to artwork IDs used as frames
        frame-delays: (list 32 uint),  ;; Delay between frames in milliseconds
        created-at: uint
    }
)

;; Public Functions

;; Create new pixel art
(define-public (create-artwork (width uint) (height uint) (pixels (list 4096 uint)))
    (let 
        (
            (artwork-id (var-get next-artwork-id))
            (total-pixels (* width height))
        )
        (asserts! (<= total-pixels u4096) (err u103))
        (try! (nft-mint? pixel-art artwork-id tx-sender))
        (map-set artworks artwork-id {
            owner: tx-sender,
            width: width,
            height: height,
            pixels: pixels,
            created-at: block-height
        })
        (var-set next-artwork-id (+ artwork-id u1))
        (ok artwork-id)
    )
)

;; Create animation from existing artworks
(define-public (create-animation (frame-ids (list 32 uint)) (frame-delays (list 32 uint)))
    (let
        (
            (animation-id (var-get next-animation-id))
        )
        (map-set animations animation-id {
            owner: tx-sender,
            frame-ids: frame-ids,
            frame-delays: frame-delays,
            created-at: block-height
        })
        (var-set next-animation-id (+ animation-id u1))
        (ok animation-id)
    )
)

;; Transfer artwork NFT
(define-public (transfer-artwork (artwork-id uint) (recipient principal))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) (err u101)))
        )
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        (try! (nft-transfer? pixel-art artwork-id tx-sender recipient))
        (map-set artworks artwork-id (merge artwork { owner: recipient }))
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-artwork (artwork-id uint))
    (map-get? artworks artwork-id)
)

(define-read-only (get-animation (animation-id uint))
    (map-get? animations animation-id)
)

(define-read-only (get-artwork-owner (artwork-id uint))
    (ok (nft-get-owner? pixel-art artwork-id))
)

(define-read-only (get-owned-artworks (user principal))
    (ok (nft-get-owner? pixel-art user))
)