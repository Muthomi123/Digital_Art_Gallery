module digital_art_gallery::digital_art_gallery {

    use std::string::{Self, String};
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::url::{Self, Url};
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use sui::object_table::{Self, ObjectTable};
    use sui::event;
    use sui::tx_context::{Self, TxContext};

    const NOT_THE_OWNER: u64 = 0;
    // const INSUFFICIENT_FUNDS: u64 = 1;
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
        artist: address,
        counter: u64,
        artworks: ObjectTable<u64, Artwork>,
    }

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

    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            Gallery {
                id: object::new(ctx),
                artist: tx_context::sender(ctx),
                counter: 0,
                artworks: object_table::new(ctx),
            }
        )
    }
    
    // Function to create Artwork
    public entry fun create_artwork(
        title: vector<u8>,
        img_url: vector<u8>,
        year: u64,
        price: u64,
        description: vector<u8>,
        gallery: &mut Gallery,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(price > MIN_ART_PRICE, INVALID_VALUE);
        transfer::public_transfer(payment, gallery.artist);
        gallery.counter = gallery.counter +1;
        let id = object::new(ctx);

        event::emit(
            ArtCreated {
                id: object::uid_to_inner(&id),
                title: string::utf8(title),
                artist:tx_context::sender(ctx),
                year: year,
                description: string::utf8(description),
            }
        );

        let artwork = Artwork {
            id: id,
            title: string::utf8(title),
            artist: tx_context::sender(ctx),
            year: year,
            img_url: url::new_unsafe_from_bytes(img_url),
            description: string::utf8(description),
            for_sale: true,
            price: price,
        };

        object_table::add(&mut gallery.artworks, gallery.counter, artwork);
    }

    // Function to add Artwork to gallery
    public entry fun add_artwork_to_gallery(
        gallery: &mut Gallery,
        artwork: Artwork,
        ctx: &mut TxContext
    ) {
        assert!(artwork.artist == tx_context::sender(ctx), NOT_THE_OWNER);
        gallery.counter = gallery.counter +1;
        object_table::add(&mut gallery.artworks, gallery.counter, artwork);
    }
    
    
    // Function to Update Artwork Properties
    public entry fun update_artwork_properties(
        artwork: &mut Artwork,
        title: vector<u8>,
        year: u64,
        description: vector<u8>,
        for_sale: bool,
        price: u64,
        user_address: address,
    ) {
        assert!(user_address == artwork.artist, NOT_THE_OWNER);
        artwork.title = string::utf8(title);
        artwork.year = year;
        artwork.description = string::utf8(description);
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
        gallery.artist
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

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx); 
    }

}