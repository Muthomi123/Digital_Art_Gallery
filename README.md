
# Digital Art Gallery Module 🎨

The **Digital Art Gallery** is a blockchain-based application designed to manage and transact digital art assets using the Sui blockchain platform. It allows users to securely and transparently manage digital artwork ownership, listing, updates, and sales, ensuring the traceability of ownership changes and transactions.

## Struct Definitions

### `Artwork`
- **id**: Unique identifier for the artwork.
- **title**: Title of the artwork.
- **artist**: Address of the artwork's artist (owner).
- **year**: Year the artwork was created.
- **price**: Price of the artwork.
- **img_url**: URL of the artwork's image.
- **description**: Description of the artwork.
- **for_sale**: Boolean indicating whether the artwork is up for sale.

### `Gallery`
- **id**: Unique identifier for the gallery.
- **artist**: Address of the gallery's artist (owner).
- **counter**: Counter for the number of artworks in the gallery.
- **artworks**: Collection of artwork objects.

## Events

- **ArtCreated**: Triggered when a new artwork is created.
- **ArtUpdated**: Triggered when an artwork's properties are updated.
- **ArtSold**: Triggered when an artwork is sold.
- **ArtDeleted**: Triggered when an artwork is deleted.

## Public Entry Functions

- **init**: Initializes the gallery object with the artist's address as the owner.
- **create_artwork**: Creates a new artwork and adds it to the gallery, ensuring the price provided is valid.
- **add_artwork_to_gallery**: Adds an existing artwork to the gallery if the user is the artist.
- **update_artwork_properties**: Updates the properties of an existing artwork if the user is the artist.
- **buy_artwork**: Allows a buyer to purchase an artwork if it is for sale, transferring payment to the seller and ownership to the buyer.
- **delete_artwork**: Deletes an artwork if the user is the artist.
- **get_artist**: Returns the artist's address associated with the gallery.
- **get_artwork_info**: Fetches the information of an artwork from the gallery.

## Usage Guidelines

### SUI CLI Interaction
- Use the SUI CLI to call functions like `create_artwork`, `update_artwork_properties`, and `buy_artwork`.
- Provide the required transaction context and function arguments as necessary.
- Monitor transaction logs to verify events and state changes.

### Web Interface Development (Optional)
- Build a web application to interact with this module, providing a user-friendly interface for artists and buyers.
- Implement features to handle transactions and display artwork information securely.

## Conclusion

The Digital Art Gallery module empowers artists and collectors to manage and exchange artworks with transparency and security. It encourages creativity and direct connections between artists and potential buyers.
