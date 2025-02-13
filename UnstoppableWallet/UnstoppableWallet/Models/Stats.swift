import MarketKit

enum StatPage: String {
    case aboutApp = "about_app"
    case accountExtendedPrivateKey = "account_extended_private_key"
    case accountExtendedPublicKey = "account_extended_public_key"
    case addToken = "add_token"
    case advancedSearch = "advanced_search"
    case advancedSearchResults = "advanced_search_results"
    case appStatus = "app_status"
    case appearance
    case backupManager = "backup_manager"
    case backupPromptAfterCreate = "backup_prompt_after_create"
    case backupRequired = "backup_required"
    case balance
    case baseCurrency = "base_currency"
    case bip32RootKey = "bip32_root_key"
    case birthdayInput = "birthday_input"
    case blockchainSettings = "blockchain_settings"
    case blockchainSettingsBtc = "blockchain_settings_btc"
    case blockchainSettingsEvm = "blockchain_settings_evm"
    case blockchainSettingsEvmAdd = "blockchain_settings_evm_add"
    case cexWithdrawConfirmation = "cex_withdraw_confirmation"
    case cloudBackup = "cloud_backup"
    case coinAnalytics = "coin_analytics"
    case coinAnalyticsActiveAddresses = "coin_analytics_active_addresses"
    case coinAnalyticsCexVolume = "coin_analytics_cex_volume"
    case coinAnalyticsDexLiquidity = "coin_analytics_dex_liquidity"
    case coinAnalyticsDexVolume = "coin_analytics_dex_volume"
    case coinAnalyticsTvl = "coin_analytics_tvl"
    case coinAnalyticsTxCount = "coin_analytics_tx_count"
    case coinCategory = "coin_category"
    case coinManager = "coin_manager"
    case coinMarkets = "coin_markets"
    case coinOverview = "coin_overview"
    case coinPage = "coin_page"
    case coinRankAddress = "coin_rank_address"
    case coinRankCexVolume = "coin_rank_cex_volume"
    case coinRankDexLiquidity = "coin_rank_dex_liquidity"
    case coinRankDexVolume = "coin_rank_dex_volume"
    case coinRankFee = "coin_rank_fee"
    case coinRankHolders = "coin_rank_holders"
    case coinRankRevenue = "coin_rank_revenue"
    case coinRankTxCount = "coin_rank_tx_count"
    case contactAddToExisting = "contact_add_to_existing"
    case contactNew = "contact_new"
    case contacts
    case contactUs = "contact_us"
    case donate
    case donateAddressList = "donate_address_list"
    case doubleSpend = "double_spend"
    case education
    case evmAddress = "evm_address"
    case evmPrivateKey = "evm_private_key"
    case exportFull = "export_full"
    case exportFullToCloud = "export_full_to_cloud"
    case exportFullToFiles = "export_full_to_files"
    case externalBlockExplorer = "external_block_explorer"
    case externalCoinWebsite = "external_coin_website"
    case externalCoinWhitePaper = "external_coin_white_paper"
    case externalCompanyWebsite = "external_company_website"
    case externalGithub = "external_github"
    case externalMarketPair = "external_market_pair"
    case externalNews = "external_news"
    case externalReddit = "external_reddit"
    case externalTelegram = "external_telegram"
    case externalTwitter = "external_twitter"
    case externalWebsite = "external_website"
    case faq
    case globalMetricsDefiCap = "global_metrics_defi_cap"
    case globalMetricsMarketCap = "global_metrics_market_cap"
    case globalMetricsTvlInDefi = "global_metrics_tvl_in_defi"
    case globalMetricsEtf = "global_metrics_etf"
    case globalMetricsVolume = "global_metrics_volume"
    case guide
    case importFull = "import_full"
    case importFullFromCloud = "import_full_from_cloud"
    case importFullFromFiles = "import_full_from_files"
    case importWallet = "import_wallet"
    case importWalletFromCloud = "import_wallet_from_cloud"
    case importWalletFromExchangeWallet = "import_wallet_from_exchange_wallet"
    case importWalletFromFiles = "import_wallet_from_files"
    case importWalletFromKey = "import_wallet_from_key"
    case importWalletFromKeyAdvanced = "import_wallet_from_key_advanced"
    case importWalletNonStandard = "import_wallet_non_standard"
    case indicators
    case info
    case language
    case main
    case manageWallet = "manage_wallet"
    case manageWallets = "manage_wallets"
    case manualBackup = "manual_backup"
    case marketOverview = "market_overview"
    case markets
    case marketSearch = "market_search"
    case news
    case newWallet = "new_wallet"
    case newWalletAdvanced = "new_wallet_advanced"
    case privacy
    case privateKeys = "private_keys"
    case publicKeys = "public_keys"
    case rateUs = "rate_us"
    case receive
    case receiveTokenList = "receive_token_list"
    case recoveryPhrase = "recovery_phrase"
    case resend
    case restoreSelect = "restore_select"
    case scanQrCode = "scan_qr_code"
    case sector
    case security
    case send
    case sendConfirmation = "send_confirmation"
    case sendTokenList = "send_token_list"
    case settings
    case swap
    case switchWallet = "switch_wallet"
    case tellFriends = "tell_friends"
    case terms
    case tokenPage = "token_page"
    case topCoins = "top_coins"
    case topMarketPairs = "top_market_pairs"
    case topNftCollections = "top_nft_collections"
    case topPlatform = "top_platform"
    case topPlatforms = "top_platforms"
    case transactionFilter = "transaction_filter"
    case transactionInfo = "transaction_info"
    case transactions
    case unlinkWallet = "unlink_wallet"
    case vipSupport = "vip_support"
    case walletConnect = "wallet_connect"
    case walletConnectRequest = "wallet_connect_request"
    case walletConnectSession = "wallet_connect_session"
    case watchlist
    case watchWallet = "watch_wallet"
    case whatsNews = "whats_news"
    case widget
}

enum StatSection: String {
    case addressFrom = "address_from"
    case addressRecipient = "address_recipient"
    case addressSpender = "address_spender"
    case addressTo = "address_to"
    case coins
    case deepLink = "deep_link"
    case input
    case news
    case pairs
    case sectors
    case platforms
    case popular
    case recent
    case searchResults = "search_results"
    case status
    case timeLock = "time_lock"
    case topGainers = "top_gainers"
    case topLosers = "top_losers"
    case topPlatforms = "top_platforms"
    case qrScan = "qr_scan"
    case watchlist
}

enum StatEvent {
    case add(entity: StatEntity)
    case addEvmSource(chainUid: String)
    case addToken(token: Token)
    case addToWallet
    case addToWatchlist(coinUid: String)
    case approveRequest(chainUid: String)
    case cancel
    case clear(entity: StatEntity)
    case connect, reconnect, disconnect, reject
    case copy(entity: StatEntity)
    case copyAddress(chainUid: String)
    case createWallet(walletType: String)
    case delete(entity: StatEntity)
    case deleteCustomEvmSource(chainUid: String)
    case disableToken(token: Token)
    case edit(entity: StatEntity)
    case enableToken(token: Token)
    case exportFull
    case hideBalanceButtons(hide: Bool)
    case importWallet(walletType: String)
    case importFull
    case open(page: StatPage)
    case openBlockchainSettingsBtc(chainUid: String)
    case openBlockchainSettingsEvm(chainUid: String)
    case openBlockchainSettingsEvmAdd(chainUid: String)
    case openCategory(categoryUid: String)
    case openCoin(coinUid: String)
    case openPlatform(chainUid: String)
    case openReceive(token: Token)
    case openResend(chainUid: String, type: String)
    case openSector(sectorUid: String)
    case openSend(token: Token)
    case openSendTokenList(coinUid: String?, chainUid: String?)
    case openTokenInfo(token: Token)
    case openTokenPage(element: WalletModule.Element)
    case paste(entity: StatEntity)
    case refresh
    case rejectRequest(chainUid: String)
    case removeAmount
    case removeFromWallet
    case removeFromWatchlist(coinUid: String)
    case scanQr(entity: StatEntity)
    case select(entity: StatEntity)
    case selectAppIcon(iconUid: String)
    case openArticle(relativeUrl: String)
    case selectBalanceConversion(coinUid: String)
    case selectBalanceValue(type: String)
    case selectLaunchScreen(type: String)
    case selectTheme(type: String)
    case setAmount
    case share(entity: StatEntity)
    case showMarketsTab(shown: Bool)
    case showSignals(shown: Bool)
    case switchBaseCurrency(code: String)
    case switchBtcSource(chainUid: String, type: BtcRestoreMode)
    case switchChartPeriod(period: StatPeriod)
    case switchEvmSource(chainUid: String, name: String)
    case switchField(field: StatField)
    case switchFilterType(type: String)
    case switchLanguage(language: String)
    case switchMarketTop(marketTop: StatMarketTop)
    case switchPeriod(period: StatPeriod)
    case switchPriceChangeMode(mode: PriceChangeMode)
    case switchSortType(sortType: StatSortType)
    case switchTab(tab: StatTab)
    case switchTvlChain(chain: String)
    case toggleBalanceHidden
    case toggleConversionCoin
    case toggleHidden
    case toggleIndicators(shown: Bool)
    case togglePrice
    case toggleSortDirection
    case toggleTvlField(field: String)
    case walletConnectPair
    case watchWallet(walletType: String)

    var name: String {
        switch self {
        case .add, .addToken: return "add"
        case .addEvmSource: return "add_evm_source"
        case .addToWallet: return "add_to_wallet"
        case .addToWatchlist: return "add_to_watchlist"
        case .approveRequest: return "approve_request"
        case .cancel: return "cancel"
        case .clear: return "clear"
        case .connect: return "connect"
        case .copy, .copyAddress: return "copy"
        case .createWallet: return "create_wallet"
        case .delete: return "delete"
        case .deleteCustomEvmSource: return "delete_custom_evm_source"
        case .disableToken: return "disable_token"
        case .disconnect: return "disconnect"
        case .edit: return "edit"
        case .enableToken: return "enable_token"
        case .exportFull: return "export_full"
        case .hideBalanceButtons: return "hide_balance_buttons"
        case .importFull: return "import_full"
        case .importWallet: return "import_wallet"
        case .open, .openCategory, .openCoin, .openPlatform, .openReceive, .openResend, .openSector, .openSend, .openSendTokenList, .openTokenPage,
             .openBlockchainSettingsBtc, .openBlockchainSettingsEvm, .openBlockchainSettingsEvmAdd: return "open_page"
        case .openTokenInfo: return "open_token_info"
        case .paste: return "paste"
        case .reconnect: return "reconnect"
        case .refresh: return "refresh"
        case .reject: return "disconnect"
        case .rejectRequest: return "reject_request"
        case .removeAmount: return "remove_amount"
        case .removeFromWallet: return "remove_from_wallet"
        case .removeFromWatchlist: return "remove_from_watchlist"
        case .scanQr: return "scan_qr"
        case .select: return "select"
        case .selectAppIcon: return "select_app_icon"
        case .openArticle: return "open_article"
        case .selectBalanceConversion: return "select_balance_conversion"
        case .selectBalanceValue: return "select_balance_value"
        case .selectLaunchScreen: return "select_launch_screen"
        case .selectTheme: return "select_theme"
        case .setAmount: return "set_amount"
        case .share: return "share"
        case .showMarketsTab: return "show_markets_tab"
        case .showSignals: return "show_signals"
        case .switchBaseCurrency: return "switch_base_currency"
        case .switchBtcSource: return "switch_btc_source"
        case .switchChartPeriod: return "switch_chart_period"
        case .switchEvmSource: return "switch_evm_source"
        case .switchField: return "switch_field"
        case .switchFilterType: return "switch_filter_type"
        case .switchLanguage: return "switch_language"
        case .switchMarketTop: return "switch_market_top"
        case .switchPeriod: return "switch_period"
        case .switchPriceChangeMode: return "switch_price_change_mode"
        case .switchSortType: return "switch_sort_type"
        case .switchTab: return "switch_tab"
        case .switchTvlChain: return "switch_tvl_chain"
        case .toggleBalanceHidden: return "toggle_balance_hidden"
        case .toggleConversionCoin: return "toggle_conversion_coin"
        case .toggleHidden: return "toggle_hidden"
        case .toggleIndicators: return "toggle_indicators"
        case .togglePrice: return "toggle_price"
        case .toggleSortDirection: return "toggle_sort_direction"
        case .toggleTvlField: return "toggle_tvl_field"
        case .walletConnectPair: return "wallet_connect_pair"
        case .watchWallet: return "watch_wallet"
        }
    }

    var params: [StatParam: Any]? {
        switch self {
        case let .add(entity): return [.entity: entity.rawValue]
        case let .addEvmSource(chainUid): return [.chainUid: chainUid]
        case let .addToken(token): return params(token: token).merging([.entity: StatEntity.token.rawValue]) { $1 }
        case let .addToWatchlist(coinUid): return [.coinUid: coinUid]
        case let .approveRequest(chainUid): return [.chainUid: chainUid]
        case let .clear(entity): return [.entity: entity.rawValue]
        case let .copy(entity): return [.entity: entity.rawValue]
        case let .copyAddress(chainUid): return [.entity: StatEntity.address.rawValue, .chainUid: chainUid]
        case let .createWallet(walletType): return [.walletType: walletType]
        case let .delete(entity): return [.entity: entity.rawValue]
        case let .deleteCustomEvmSource(coinUid): return [.page: StatPage.blockchainSettingsEvm.rawValue, .coinUid: coinUid]
        case let .disableToken(token): return params(token: token)
        case let .edit(entity): return [.entity: entity.rawValue]
        case let .enableToken(token): return params(token: token)
        case let .hideBalanceButtons(hide): return [.shown: hide]
        case let .importWallet(walletType): return [.walletType: walletType]
        case let .open(page): return [.page: page.rawValue]
        case let .openBlockchainSettingsBtc(chainUid: chainUid): return [.page: StatPage.blockchainSettingsBtc.rawValue, .chainUid: chainUid]
        case let .openBlockchainSettingsEvm(chainUid: chainUid): return [.page: StatPage.blockchainSettingsEvm.rawValue, .chainUid: chainUid]
        case let .openBlockchainSettingsEvmAdd(chainUid: chainUid): return [.page: StatPage.blockchainSettingsEvmAdd.rawValue, .chainUid: chainUid]
        case let .openCategory(categoryUid): return [.page: StatPage.coinCategory.rawValue, .categoryUid: categoryUid]
        case let .openCoin(coinUid): return [.page: StatPage.coinPage.rawValue, .coinUid: coinUid]
        case let .openSendTokenList(coinUid, chainUid):
            var params: [StatParam: Any] = [.page: StatPage.sendTokenList.rawValue]
            params[.coinUid] = coinUid
            params[.chainUid] = chainUid
            return params
        case let .selectAppIcon(iconUid): return [.iconUid: iconUid]
        case let .openArticle(relativeUrl): return [.relativeUrl: relativeUrl]
        case let .rejectRequest(chainUid): return [.chainUid: chainUid]
        case let .selectBalanceConversion(coinUid): return [.coinUid: coinUid]
        case let .selectBalanceValue(type): return [.type: type]
        case let .selectLaunchScreen(type): return [.type: type]
        case let .selectTheme(type): return [.type: type]
        case let .openPlatform(chainUid): return [.page: StatPage.topPlatform.rawValue, .chainUid: chainUid]
        case let .openReceive(token): return params(token: token).merging([.page: StatPage.receive.rawValue]) { $1 }
        case let .openResend(chainUid, type): return [.page: StatPage.resend.rawValue, .chainUid: chainUid, .type: type]
        case let .openSector(sectorUid): return [.page: StatPage.sector.rawValue, .sectorUid: sectorUid]
        case let .openSend(token): return params(token: token).merging([.page: StatPage.send.rawValue]) { $1 }
        case let .openTokenPage(element):
            var params: [StatParam: Any] = [.page: StatPage.tokenPage.rawValue]
            switch element {
            case let .wallet(wallet): params.merge(self.params(token: wallet.token)) { $1 }
            case let .cexAsset(cexAsset): params[.assetId] = cexAsset.id
            }
            return params
        case let .openTokenInfo(token): return params(token: token)
        case let .paste(entity): return [.entity: entity.rawValue]
        case let .removeFromWatchlist(coinUid): return [.coinUid: coinUid]
        case let .scanQr(entity): return [.entity: entity.rawValue]
        case let .select(entity): return [.entity: entity.rawValue]
        case let .share(entity): return [.entity: entity.rawValue]
        case let .showMarketsTab(shown): return [.shown: shown]
        case let .showSignals(shown): return [.shown: shown]
        case let .switchBaseCurrency(code: code): return [.currencyCode: code]
        case let .switchBtcSource(chainUid, type): return [.chainUid: chainUid, .type: type.rawValue]
        case let .switchChartPeriod(period): return [.period: period.rawValue]
        case let .switchEvmSource(chainUid, name): return [.chainUid: chainUid, .type: name]
        case let .switchField(field): return [.field: field.rawValue]
        case let .switchFilterType(type): return [.type: type]
        case let .switchLanguage(language): return [.language: language]
        case let .switchMarketTop(marketTop): return [.marketTop: marketTop.rawValue]
        case let .switchPeriod(period): return [.period: period.rawValue]
        case let .switchPriceChangeMode(priceChangeMode): return [.changeMode: priceChangeMode.statName]
        case let .switchSortType(sortType): return [.type: sortType.rawValue]
        case let .switchTab(tab): return [.tab: tab.rawValue]
        case let .switchTvlChain(chain): return [.tvlChain: chain]
        case let .toggleIndicators(shown): return [.shown: shown]
        case let .toggleTvlField(field): return [.field: field]
        case let .watchWallet(walletType): return [.walletType: walletType]
        default: return nil
        }
    }

    private func params(token: Token) -> [StatParam: Any] {
        var params: [StatParam: Any] = [.coinUid: token.coin.uid, .chainUid: token.blockchainType.uid]
        params[.derivation] = token.type.derivation?.rawValue
        params[.bitcoinCashCoinType] = token.type.bitcoinCashCoinType?.rawValue
        return params
    }
}

enum StatParam: String {
    case assetId = "asset_id"
    case bitcoinCashCoinType = "bitcoin_cash_coin_type"
    case categoryUid = "category_uid"
    case chainUid = "chain_uid"
    case currencyCode = "currency_code"
    case coinUid = "coin_uid"
    case derivation
    case entity
    case field
    case hide
    case iconUid = "icon_uid"
    case language
    case marketTop = "market_top"
    case page
    case period
    case changeMode = "change_mode"
    case relativeUrl = "relative_url"
    case sectorUid = "sector_uid"
    case shown
    case tab
    case tvlChain = "tvl_chain"
    case type
    case walletType = "wallet_type"
}

enum StatTab: String {
    case markets, balance, transactions, settings
    case coins, overview, news, pairs, platforms, watchlist, sectors
    case analytics
    case all, incoming, outgoing, swap, approve
}

enum StatSortType: String {
    case balance
    case name
    case priceChange = "price_change"

    case manual
    case highestCap = "highest_cap"
    case lowestCap = "lowest_cap"
    case highestVolume = "highest_volume"
    case lowestVolume = "lowest_volume"
    case topGainers = "top_gainers"
    case topLosers = "top_losers"

    case highestAssets = "highest_assets"
    case lowestAssets = "lowest_assets"
    case inflow
    case outflow
}

enum StatPeriod: String {
    case hour24 = "24h"
    case day1 = "1d"
    case week1 = "1w"
    case week2 = "2w"
    case month1 = "1m"
    case month3 = "3m"
    case month6 = "6m"
    case year1 = "1y"
    case year2 = "2y"
    case year5 = "5y"
    case all
}

enum StatField: String {
    case marketCap = "market_cap"
    case volume
    case price
}

enum StatMarketTop: String {
    case top100
    case top200
    case top300
    case top500
    case top1000
    case top1500
    case top2000
    case top2500
}

enum StatEntity: String {
    case account
    case address
    case all
    case blockchain
    case cloudBackup = "cloud_backup"
    case contractAddress = "contract_address"
    case derivation
    case evmAddress = "evm_address"
    case evmPrivateKey = "evm_private_key"
    case key
    case passphrase
    case receiveAddress = "receive_address"
    case recoveryPhrase = "recovery_phrase"
    case session
    case status
    case token
    case transactionId = "transaction_id"
    case wallet
    case walletConnectPair = "wallet_connect_pair"
    case walletName = "wallet_name"
}
