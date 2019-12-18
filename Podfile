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
  pod 'EosioSwiftAbieosSerializationProvider', git: 'https://github.com/horizontalsystems/eosio-swift-abieos-serialization-provider.git'

  pod 'BinanceChainKit.swift'

  pod 'HdWalletKit.swift'

  pod 'XRatesKit.swift'
  pod 'FeeRateKit.swift'

  pod 'UIExtensions.swift'
  pod 'ActionSheet.swift'
  pod 'HUD.swift'
  pod 'Chart.swift'
  pod 'SectionsTableView.swift'

  pod 'Alamofire'
  pod 'AlamofireImage'
  pod 'ObjectMapper'

  pod 'GRDB.swift'

  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGRDB'

  pod 'BigInt'
  pod 'KeychainAccess'
  pod 'SnapKit'
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
