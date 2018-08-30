platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

project 'Wallet/Wallet'

target :Bank do
  pod 'WalletKit', git: 'https://github.com/horizontalsystems/WalletKit-iOS.git', branch: 'dev'

  pod 'Alamofire'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'
  pod 'RealmSwift'
  pod "RxRealm"

  pod 'GrouviExtensions'
  pod 'GrouviActionSheet'
  pod 'GrouviHUD' #, :path => '../GrouviHUD'
  pod 'SectionsTableViewKit' #, :path => '../SectionsTableViewKit'

  pod 'RxCocoa'
  pod "SnapKit"
end

target :WalletTests do
  pod "Cuckoo"
end
