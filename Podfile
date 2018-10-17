platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

project 'Wallet/Wallet'

target :Bank do
  pod 'HSBitcoinKit', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'
  pod 'HSEthereumKit', git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git'
  pod 'CryptoEthereumSwift', git: 'https://github.com/horizontalsystems/CryptoEthereumSwift.git'

  pod 'Alamofire'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'
  pod 'RealmSwift'
  pod "RxRealm"

  pod 'GrouviExtensions', git: 'https://github.com/horizontalsystems/GrouviExtensions.git', branch: 'master'
  pod 'GrouviActionSheet', git: 'https://github.com/horizontalsystems/GrouviActoinSheet.git', branch: 'master'
  # pod 'GrouviActionSheet', :path => '../GrouviActionSheet'
  pod 'GrouviHUD', git: 'https://github.com/horizontalsystems/GrouviHUD.git', branch: 'master'
  # pod 'GrouviHUD', :path => '../GrouviHUD'
  pod 'SectionsTableViewKit' #, :path => '../SectionsTableViewKit'

  pod 'KeychainAccess'

  pod 'RxCocoa'
  pod "SnapKit"
end

target :WalletTests do
  pod 'RxSwift'
  pod "Cuckoo"
end
