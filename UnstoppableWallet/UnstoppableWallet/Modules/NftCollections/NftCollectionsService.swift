import Foundation
import RxSwift
import RxRelay
import CurrencyKit

class NftCollectionsService {
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(currencyKit: CurrencyKit.Kit) {
        self.currencyKit = currencyKit

        syncItems()
    }

    private func syncItems() {
        items = [
            Item(imageUrl: "https://lh3.googleusercontent.com/34ogFJ5huHsQ38cwS59DTgSeaRjFTcCwu0ZSKBv8_Y8UAdiYnq5VACaBIYy09fXOKaWnrjfLQxI7PsLjedm4RJrO-VCbwASkF2dlsWc=w72", name: "CryptoPunks", tokens: [
                TokenItem(imageUrl: "https://lh3.googleusercontent.com/DsOEz1GCOdms2i7YDoH976ie1iQRYp3ATpu_CHddlBbCYfT0KX0neWEY1pHJEFIPR-o-M1eYEQY5rcPYqBNPe5oiXtl6YDjaExq1kC0=w335", name: "CryptoPunk #170", floorPrice: 23500, lastPrice: 38200),
                TokenItem(imageUrl: "https://lh3.googleusercontent.com/tnle-unQg5Vw3y6--Zyd8mFW_7YfGZYM3NgAh0m0cKBIqt8Qsa_AIjGKdGgHWbkInSISxQCWPGZ_Ku8BDAO0aC_Zsbo1WkaIF8kv=w335", name: "CryptoPunk #1116", floorPrice: 16100, lastPrice: 27400)
            ]),
            Item(imageUrl: "https://lh3.googleusercontent.com/mPpOei8345NWTVxmzN5wv_jU4xWsG_KZWBH28pFMuKdLQz-hq5AzeKMC3zA9-dMwZdKiZ6tvvpC4uzZzgYScpi6jEWTen3VUgrmjgw=w72", name: "Bored Ape Yacht Club", tokens: [
                TokenItem(imageUrl: "https://lh3.googleusercontent.com/RTvkOSzBsTG0E54t8g4MyXTxETwoIy-91kYLIogGPZx05TX751dRAB7AOSrS74t5Yykay8LuCzy4Ep9UsTaOotYr5lBvpu_oEGoe=w600", name: "Bored Ape #7", floorPrice: 45800, lastPrice: 17700)
            ]),
            Item(imageUrl: "https://lh3.googleusercontent.com/KiU7VA0H20i3eyKgRQWTTyQyqOH5it_mppRvX4iaE35rfo066h2DVpM4iQrp-Jwo5_PniPtS8Qqi8pug3ftNK2o-aBIb7wxeNz-g4g=w72", name: "Cool Cats NFT", tokens: [
                TokenItem(imageUrl: "https://lh3.googleusercontent.com/3JWSITJETJAvxTaCzI-aEPsVUCcPRRXrU12wJ5q9YO_huBPdICVtfQq8RP23bDC_4lTdj7Yfi9lFIgPSIYqy6K_JNOSXmAHz0Z1e=w335", name: "Cool Cat #4638", floorPrice: 450, lastPrice: 160),
                TokenItem(imageUrl: "https://lh3.googleusercontent.com/R9OKtUkqOdZNdXs2knGKQ993Aaa27RCfpLU6f_u3e9Rmr1O7gCQ0GITO3t_IPRGsLE1ZuZzgzQ-ul1SNj31MctlPC7ro3fwmeT8HFQ=w335", name: "Cool Cat #4604", floorPrice: 550, lastPrice: 170),
                TokenItem(imageUrl: "https://lh3.googleusercontent.com/Swbn4NzXbxm5OwzBSAwVw3w0t6HRloIzNTj9vE1iGLIk3gNJbqe_zvH-x3HeAqypikiR4MKWBJ89YAgJHrDodZij7XZano_EF9pyxnE=w335", name: "Cool Cat #8515", floorPrice: 650, lastPrice: 180),
            ])
        ]
    }

}

extension NftCollectionsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}

extension NftCollectionsService {

    struct Item {
        let imageUrl: String
        let name: String
        let tokens: [TokenItem]
    }

    struct TokenItem {
        let imageUrl: String
        let name: String
        let floorPrice: Decimal
        let lastPrice: Decimal
    }

}
