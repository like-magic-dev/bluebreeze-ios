Pod::Spec.new do |spec|
  spec.name          = 'BlueBreeze'
  spec.version       = '0.0.7'
  spec.license       = { :type => 'MIT' }
  spec.homepage      = 'https://github.com/like-magic-dev/bluebreeze-ios'
  spec.authors       = { 'Alessandro Mulloni' => 'ale@likemagic.dev' }
  spec.summary       = 'BlueBreeze iOS SDK - A modern Bluetooth LE library'
  spec.source        = { :git => 'https://github.com/like-magic-dev/bluebreeze-ios.git', :tag => '0.0.7' }
  spec.module_name   = 'BlueBreeze'
  spec.swift_version = '5.0'

  spec.ios.deployment_target  = '13.0'
  spec.osx.deployment_target  = '11.5'

  spec.source_files       = 'BlueBreeze/**/*.swift'
end