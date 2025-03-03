;; PixelNest - Pixel Art Creation and Storage Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-collection (err u104))
(define-constant err-transfer-failed (err u105))
(define-constant err-invalid-input (err u106))
(define-constant max-pixel-count u4096)

;; Data Variables
(define-data-var next-artwork-id uint u0)
(define-data-var next-animation-id uint u0)
(define-data-var next-collection-id uint u0)
(define-data-var total-artworks uint u0)

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
        pixels: (list 4096 uint),
        created-at: uint,
        collection-id: (optional uint),
        transfer-restricted: bool,
        deleted: bool
    }
)

(define-map artwork-metadata
    uint
    {
        title: (optional (string-ascii 64)),
        description: (optional (string-ascii 256)),
        tags: (list 5 (string-ascii 32))
    }
)

(define-map events
    {block: uint, index: uint}
    {
        event-type: (string-ascii 32),
        artwork-id: uint,
        actor: principal,
        timestamp: uint
    }
)

;; Helper Functions
(define-private (validate-pixels (width uint) (height uint) (pixels (list 4096 uint)))
    (and 
        (<= (* width height) max-pixel-count)
        (>= (len pixels) (* width height))
    )
)

(define-private (emit-event (event-type (string-ascii 32)) (artwork-id uint))
    (let
        ((event-key {block: block-height, index: (var-get total-artworks)}))
        (map-set events event-key {
            event-type: event-type,
            artwork-id: artwork-id,
            actor: tx-sender,
            timestamp: block-height
        })
        (ok true)
    )
)

;; Public Functions
(define-public (create-artwork (width uint) (height uint) (pixels (list 4096 uint)))
    (let
        ((artwork-id (var-get next-artwork-id)))
        (asserts! (validate-pixels width height pixels) err-invalid-input)
        (try! (nft-mint? pixel-art artwork-id tx-sender))
        (map-set artworks artwork-id {
            owner: tx-sender,
            width: width,
            height: height,
            pixels: pixels,
            created-at: block-height,
            collection-id: none,
            transfer-restricted: false,
            deleted: false
        })
        (var-set next-artwork-id (+ artwork-id u1))
        (var-set total-artworks (+ (var-get total-artworks) u1))
        (try! (emit-event "create" artwork-id))
        (ok artwork-id)
    )
)

(define-public (delete-artwork (artwork-id uint))
    (let
        ((artwork (unwrap! (map-get? artworks artwork-id) err-not-found)))
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        (asserts! (not (get deleted artwork)) err-not-found)
        (map-set artworks artwork-id (merge artwork {deleted: true}))
        (try! (emit-event "delete" artwork-id))
        (var-set total-artworks (- (var-get total-artworks) u1))
        (ok true)
    )
)

;; Getter Functions
(define-read-only (get-platform-stats)
    (ok {
        total-artworks: (var-get total-artworks),
        next-artwork-id: (var-get next-artwork-id)
    })
)

;; [Previous functions remain unchanged...]
