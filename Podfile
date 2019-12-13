platform :ios, '12'
use_modular_headers!

inhibit_all_warnings!

project 'BankWallet/BankWallet'

def appPods
  pod 'BitcoinKit.swift'
  pod 'BitcoinCashKit.swift'
  pod 'DashKit.swift'
  pod 'Hodler.swift'

  pod 'EthereumKit.swift'
  pod 'Erc20Kit.swift'

  pod 'EosKit.swift'
  pod 'EosioSwift', git: 'https://github.com/horizontalsystems/eosio-swift'
  pod 'EosioSwiftAbieosSerializationProvider', git: 'https://github.com/horizontalsystems/eosio-swift-abieos-serialization-provider.git'

  pod 'BinanceChainKit.swift'

  pod 'HSHDWalletKit'

  pod 'XRatesKit.swift', git: 'https://github.com/horizontalsystems/xrates-kit-ios'
  pod 'FeeRateKit.swift', git: 'https://github.com/horizontalsystems/blockchain-fee-rate-kit-ios'

  pod 'Alamofire'
  pod 'AlamofireImage'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'

  pod 'UIExtensions.swift', git: 'https://github.com/horizontalsystems/gui-kit'
  pod 'ActionSheet.swift', git: 'https://github.com/horizontalsystems/gui-kit'
  pod 'HUD.swift', git: 'https://github.com/horizontalsystems/gui-kit'
  pod 'SectionsTableView.swift', git: 'https://github.com/horizontalsystems/gui-kit'

  pod 'KeychainAccess'

  pod 'RxCocoa'
  pod 'SnapKit'

  pod 'GRDB.swift'
  pod 'RxGRDB'

  pod 'DeepDiff'
end

target 'Bank Dev T' do
  appPods
end

target 'Bank Dev' do
  appPods
end

target 'Bank' do
  appPods
end

target 'Bank Tests' do
  pod 'DeepDiff'
  pod 'RxSwift'
  pod 'Cuckoo'
  pod 'Quick'
  pod 'Nimble'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
