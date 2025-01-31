;; PixelNest - Pixel Art Creation and Storage Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-collection (err u104))

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
        collection-id: (optional uint)
    }
)

(define-map animations
    uint
    {
        owner: principal,
        frame-ids: (list 32 uint),  ;; References to artwork IDs used as frames
        frame-delays: (list 32 uint),  ;; Delay between frames in milliseconds
        created-at: uint,
        collection-id: (optional uint)
    }
)

(define-map collections
    uint
    {
        owner: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        artwork-ids: (list 100 uint),
        animation-ids: (list 32 uint),
        created-at: uint,
        is-public: bool
    }
)

(define-map collection-contributors
    {collection-id: uint, contributor: principal}
    bool
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
            created-at: block-height,
            collection-id: none
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
            created-at: block-height,
            collection-id: none
        })
        (var-set next-animation-id (+ animation-id u1))
        (ok animation-id)
    )
)

;; Create new collection
(define-public (create-collection (name (string-ascii 64)) (description (string-ascii 256)) (is-public bool))
    (let
        (
            (collection-id (var-get next-collection-id))
        )
        (try! (nft-mint? collection collection-id tx-sender))
        (map-set collections collection-id {
            owner: tx-sender,
            name: name,
            description: description,
            artwork-ids: (list),
            animation-ids: (list),
            created-at: block-height,
            is-public: is-public
        })
        (var-set next-collection-id (+ collection-id u1))
        (ok collection-id)
    )
)

;; Add artwork to collection
(define-public (add-artwork-to-collection (artwork-id uint) (collection-id uint))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
        )
        (asserts! (or 
            (is-eq (get owner collection) tx-sender)
            (map-get? collection-contributors {collection-id: collection-id, contributor: tx-sender})
        ) err-unauthorized)
        (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
        
        (map-set artworks artwork-id (merge artwork {collection-id: (some collection-id)}))
        (map-set collections collection-id (merge collection {
            artwork-ids: (unwrap! (as-max-len? (append (get artwork-ids collection) artwork-id) u100) err-invalid-collection)
        }))
        (ok true)
    )
)

;; Add animation to collection  
(define-public (add-animation-to-collection (animation-id uint) (collection-id uint))
    (let
        (
            (animation (unwrap! (map-get? animations animation-id) err-not-found))
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
        )
        (asserts! (or
            (is-eq (get owner collection) tx-sender)
            (map-get? collection-contributors {collection-id: collection-id, contributor: tx-sender})
        ) err-unauthorized)
        (asserts! (is-eq (get owner animation) tx-sender) err-unauthorized)
        
        (map-set animations animation-id (merge animation {collection-id: (some collection-id)}))
        (map-set collections collection-id (merge collection {
            animation-ids: (unwrap! (as-max-len? (append (get animation-ids collection) animation-id) u32) err-invalid-collection)
        }))
        (ok true)
    )
)

;; Add contributor to collection
(define-public (add-contributor (collection-id uint) (contributor principal))
    (let
        (
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
        )
        (asserts! (is-eq (get owner collection) tx-sender) err-unauthorized)
        (map-set collection-contributors {collection-id: collection-id, contributor: contributor} true)
        (ok true)
    )
)

;; Remove contributor from collection
(define-public (remove-contributor (collection-id uint) (contributor principal))
    (let
        (
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
        )
        (asserts! (is-eq (get owner collection) tx-sender) err-unauthorized)
        (map-delete collection-contributors {collection-id: collection-id, contributor: contributor})
        (ok true)
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

(define-read-only (get-collection (collection-id uint))
    (map-get? collections collection-id)
)

(define-read-only (get-artwork-owner (artwork-id uint))
    (ok (nft-get-owner? pixel-art artwork-id))
)

(define-read-only (get-owned-artworks (user principal))
    (ok (nft-get-owner? pixel-art user))
)

(define-read-only (get-collection-contributors (collection-id uint))
    (map-get? collection-contributors {collection-id: collection-id, contributor: tx-sender})
)
