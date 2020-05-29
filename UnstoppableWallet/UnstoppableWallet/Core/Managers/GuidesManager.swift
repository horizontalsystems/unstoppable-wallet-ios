class GuidesManager {
}

extension GuidesManager: IGuidesManager {

    var guides: [Guide] {
        [
            Guide(
                    title: "How to Store Bitcoins",
                    imageUrl: "https://media.gettyimages.com/photos/-picture-id540996432",
                    fileName: "tether"
            ),
            Guide(
                    title: "Libra in Simple Terms",
                    imageUrl: "https://media.gettyimages.com/photos/530d-car-head-lights-picture-id157735154",
                    fileName: "tether"
            ),
            Guide(
                    title: "Crypto Terms for Beginners",
                    imageUrl: "http://media.gettyimages.com/photos/modern-key-to-the-bmw-in-a-hand-picture-id890886864",
                    fileName: "tether"
            ),
            Guide(
                    title: "Thether is Simple Terms",
                    imageUrl: "http://media.gettyimages.com/photos/car-steel-wheels-of-a-new-bmw-coupe-picture-id516914879",
                    fileName: "tether"
            ),
        ]
    }

}
