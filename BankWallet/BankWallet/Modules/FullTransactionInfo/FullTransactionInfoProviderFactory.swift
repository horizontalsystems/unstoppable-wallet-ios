import Foundation

class FullTransactionInfoProviderFactory {

    private let apiManager: IJSONApiManager
    private let appConfigProvider: IAppConfigProvider
    private let localStorage: ILocalStorage

    init(apiManager: IJSONApiManager, appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage) {
        self.apiManager = apiManager
        self.localStorage = localStorage
        self.appConfigProvider = appConfigProvider
    }

}

extension FullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory {

    func provider(forCoin coin: String) -> IFullTransactionInfoProvider {
        let explorerId = coin.range(of: "ETH") != nil ? "BlockChair.com" : "HorizontalSystems.xyz"

        var adapter: IFullTransactionInfoAdapter
        if coin.range(of: "BTC") != nil {
            let converter: IBitcoinJSONConverter
            if explorerId == "BlockChair.com" {
                let apiUrl = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz/tx/" : "https://api.blockchair.com/bitcoin/dashboards/transaction/"
                let url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://blockchair.com/bitcoin/transaction/"
                converter = BlockChairBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else if explorerId == "BlockExplorer.com" {
                let apiUrl = appConfigProvider.testMode ? "https://testnet.blockexplorer.com/api/tx/" : "https://blockexplorer.com/api/tx/"
                let url = appConfigProvider.testMode ? "https://testnet.blockexplorer.com/tx/" : "https://blockexplorer.com/tx/"
                converter = BlockExplorerBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else if explorerId == "Btc.com" {
                let apiUrl = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://chain.api.btc.com/v3/tx/"
                let url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://btc.com/"
                converter = BtcComBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else {
            // Fallback to our server
                let apiUrl = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz/tx/" : "https://btc.horizontalsystems.xyz/tx/"
                converter = HorSysBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: apiUrl)
            }
            adapter = BitcoinTransactionInfoAdapter(jsonConverter: converter, coinCode: coin)
        } else if coin.range(of: "BCH") != nil {
            let converter: IBitcoinJSONConverter
            if explorerId == "BlockChair.com" {
                let apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz/tx/" : "https://api.blockchair.com/bitcoin-cash/dashboards/transaction/"
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz/tx/" : "https://blockchair.com/bitcoin-cash/transaction/"
                converter = BlockChairBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else if explorerId == "BlockExplorer.com" {
                let apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bitcoincash.blockexplorer.com/api/tx/"
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bitcoincash.blockexplorer.com/tx/"
                converter = BlockExplorerBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else if explorerId == "Btc.com" {
                let apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch-chain.api.btc.com/v3/tx/"
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch.btc.com/"
                converter = BtcComBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else {
                // Fallback to our server
                let apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch.horizontalsystems.xyz/tx/"
                converter = HorSysBitcoinJSONConverter(resource: explorerId, apiUrl: apiUrl, url: apiUrl)
            }
            adapter = BitcoinTransactionInfoAdapter(jsonConverter: converter, coinCode: coin)
        } else {
            let converter: IEthereumJSONConverter
            if explorerId == "Etherscan.io" {
                let apiUrl = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash="
                let url = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://etherscan.io/tx/"
                converter = EtherscanEthereumJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else if explorerId == "BlockChair.com" {
                let apiUrl = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://api.blockchair.com/ethereum/dashboards/transaction/"
                let url = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://blockchair.com/ethereum/transaction/"
                converter = BlockChairEthereumJSONConverter(resource: explorerId, apiUrl: apiUrl, url: url)
            } else {
                converter = HorSysEthereumJSONConverter(resource: explorerId, apiUrl: "https://eth.horizontalsystems.xyz/tx/", url: "https://eth.horizontalsystems.xyz/tx/")
            }
            adapter = EthereumTransactionInfoAdapter(jsonConverter: converter, coinCode: coin)
        }
        return FullTransactionProvider(apiManager: apiManager, adapter: adapter)
    }

}

//        let explorer: IExplorerType
//                let explorerType = BitcoinExplorerType.horSys
//        var explorerHelper: IFullTransactionHelper
//        let host: String
//
//        if coin.range(of: "BTC") != nil {
//            // BTC
//
//            switch explorerType {
//            case .horSys: explorer = BitcoinExplorerType.horSys
//            case .blockExplorer: explorer = BitcoinExplorerType.blockExplorer
//            case .btcCom: explorer = BitcoinExplorerType.btcCom
//            case .blockChair: explorer = BitcoinExplorerType.blockChair
//            }
//        } else if coin.range(of: "BCH") != nil {
//            // BCH
//            switch explorerType {
//            case .horSys: explorer = BitcoinCashExplorerType.horSys
//            case .blockExplorer: explorer = BitcoinCashExplorerType.blockExplorer
//            case .btcCom: explorer = BitcoinCashExplorerType.btcCom
//            case .blockChair: explorer = BitcoinCashExplorerType.blockChair
//            }
//        } else {
//            // ETH and ERC20
//            explorer = EthereumExplorerType.etherScan
//        }
//        if explorer is EthereumExplorerType {
//            return EthereumFullTransactionProvider(apiManager: apiManager, explorerType: explorer, testMode: appConfigProvider.testMode)
//        }
//        return BitcoinFullTransactionProvider(apiManager: apiManager, explorerType: explorer, coinCode: coin, testMode: appConfigProvider.testMode)
//                FullTransactionProvider(apiManager: apiManager, url: host, transactionHelper: explorerHelper, async: true)