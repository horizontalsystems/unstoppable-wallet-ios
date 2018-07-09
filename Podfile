platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'Wallet'

project 'Wallet/Wallet'
project 'WalletKit/WalletKit'

target :Wallet do
  project 'Wallet/Wallet'

  pod 'Alamofire'
  pod 'ObjectMapper'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RealmSwift'
  pod "RxRealm"
  pod "SnapKit"
end

target :WalletKit do
  project 'WalletKit/WalletKit'

  pod 'RxSwift'
  pod 'RealmSwift'
end

target :WalletTests do
  project 'Wallet/Wallet'

  pod "Cuckoo"
end
