module Gallery::digital_art_gallery {

    use std::string::{Self, String};
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::object_table::{Self, ObjectTable};
    use sui::kiosk;
    use sui::dynamic_field as df;
    use sui::dynamic_object_field as dof;
    use sui::event;
    use sui::tx_context::{Self, TxContext, sender};

    const NOT_THE_OWNER: u64 = 0;
    const INSUFFICIENT_FUNDS: u64 = 1;
    const MIN_ART_PRICE: u64 = 2;
    const ART_NOT_FOR_SALE: u64 = 3;
    const INVALID_VALUE: u64 = 4;

    struct Artwork has key, store {
        id: UID,
        title: String,
        artist: address,
        year: u64,
        price: u64,
        img_url: Url,
        description: String,
        for_sale: bool,
    }

    struct Gallery has key, store {
        id: UID,
        owner: address,
        balance: Balance<SUI>,
        counter: u64,
        artworks: ObjectTable<u64, Artwork>,
    }

    struct GalleryCap has key, store {
        id: UID,
        for: ID
    }

    struct Listing has store, copy, drop { id: ID, is_exclusive: bool }

    struct Item has store, copy, drop { id: ID }

    struct ArtCreated has copy, drop {
        id: ID,
        artist: address,
        title: String,
        year: u64,
        description: String,
    }

    struct ArtUpdated has copy, drop {
        title: String,
        year: u64,
        description: String,
        for_sale: bool,
        price: u64,
    }

    struct ArtSold has copy, drop {
        art_id: ID,
        seller: address,
        buyer: address,
        price: u64,
    }
    
    struct ArtDeleted has copy, drop {
        art_id: ID,
        title: String,
        artist: address,
    }

    public fun new(ctx: &mut TxContext) : GalleryCap {
        let id_ = object::new(ctx);
        let inner_ = object::uid_to_inner(&id_);
        transfer::share_object(
            Gallery {
                id: id_,
                owner: sender(ctx),
                balance: balance::zero(),
                counter: 0,
                artworks: object_table::new(ctx),
            }
        );
        GalleryCap {
            id: object::new(ctx),
            for: inner_
        }
    }
    
    // Function to create Artwork
    public fun mint(
        title: String,
        img_url: vector<u8>,
        year: u64,
        price: u64,
        description: String,
        ctx: &mut TxContext,
    ) : Artwork {

        let id = object::new(ctx);
        event::emit(
            ArtCreated {
                id: object::uid_to_inner(&id),
                title: title,
                artist:tx_context::sender(ctx),
                year: year,
                description: description,
            }
        );

        Artwork {
            id: id,
            title: title,
            artist: tx_context::sender(ctx),
            year: year,
            img_url: url::new_unsafe_from_bytes(img_url),
            description: description,
            for_sale: true,
            price: price,
        }
    }

    // Function to add Artwork to gallery
    public entry fun list<T: key + store>(
        self: &mut Gallery,
        cap: &GalleryCap,
        item: T,
        price: u64,
    ) {
        assert!(object::id(self) == cap.for, NOT_THE_OWNER);
        let id = object::id(&item);
        place_internal(self, item);
        df::add(&mut self.id, Listing { id, is_exclusive: false }, price);
    }

    public fun delist<T: key + store>(
        self: &mut Gallery, cap: &GalleryCap, id: ID
    ) : T {
        assert!(object::id(self) == cap.for, NOT_THE_OWNER);
        self.counter = self.counter - 1;
        df::remove_if_exists<Listing, u64>(&mut self.id, Listing { id, is_exclusive: false });
        dof::remove(&mut self.id, Item { id })    
    }

    public fun purchase<T: key + store>(
        self: &mut Gallery, id: ID, payment: Coin<SUI>
    ): T {
        let price = df::remove<Listing, u64>(&mut self.id, Listing { id, is_exclusive: false });
        let inner = dof::remove<Item, T>(&mut self.id, Item { id });

        self.counter = self.counter - 1;
        assert!(price == coin::value(&payment), INSUFFICIENT_FUNDS);
        coin::put(&mut self.balance, payment);
        inner
    }
    
    // Function to Update Artwork Properties
    public entry fun update_artwork_properties(
        artwork: &mut Artwork,
        title: String,
        year: u64,
        description: String,
        for_sale: bool,
        price: u64,
    ) {
        artwork.title = title;
        artwork.year = year;
        artwork.description = description;
        artwork.for_sale = for_sale;
        artwork.price = price;

        event::emit(
            ArtUpdated {
                title: artwork.title,
                year: artwork.year,
                description: artwork.description,
                for_sale: artwork.for_sale,
                price: artwork.price,
            }
        );
    }
    

    // Function to buy an Artwork
    public entry fun buy_artwork(
        gallery: &mut Gallery,
        art_id: u64,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let artwork = object_table::remove(&mut gallery.artworks, art_id);
        assert!(artwork.for_sale, ART_NOT_FOR_SALE);
        let buyer = tx_context::sender(ctx);
        let seller = artwork.artist;
        artwork.artist = buyer;
        artwork.for_sale = false;

        let art_id = object::uid_to_inner(&artwork.id);
        let price = artwork.price;

        transfer::public_transfer(payment, seller);
        transfer::public_transfer(artwork, buyer);
        
        event::emit(
            ArtSold {
                art_id: art_id,
                seller: seller,
                buyer: buyer,
                price: price,
            }
        );
    }

    // Function to get the artist of an Artwork
    public fun get_artist(gallery: &Gallery) : address {
        gallery.owner
    }

    // Function to fetch the Artwork Information
    public fun get_artwork_info(gallery: &Gallery,id:u64) : (
        String,
        address,
        u64,
        u64,
        Url,
        String,
        bool
    ) {
        let artwork = object_table::borrow(&gallery.artworks, id);
        (
            artwork.title,
            artwork.artist,
            artwork.year,
            artwork.price,
            artwork.img_url,
            artwork.description,
            artwork.for_sale,
        )
    }

    // Function to delete an Artwork
    public entry fun delete_artwork(
        artwork: Artwork,
        ctx: &mut TxContext,
    ) {
        assert!(tx_context::sender(ctx) == artwork.artist, NOT_THE_OWNER);
        event::emit(
            ArtDeleted {
                art_id: object::uid_to_inner(&artwork.id),
                title: artwork.title,
                artist: artwork.artist,
            }
        );

        let Artwork { id, title:_, artist:_, year:_, price:_, img_url:_, description:_, for_sale:_} = artwork;
        object::delete(id);
    }

    public fun place_internal<T: key + store>(self: &mut Gallery, item: T) {
        self.counter = self.counter + 1;
        dof::add(&mut self.id, Item { id: object::id(&item) }, item)
    }

}
