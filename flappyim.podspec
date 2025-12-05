#
# Be sure to run `pod lib lint flappyim.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'flappyim'
    s.version          = '3.15.10'
    s.summary          = "A lightweight and powerful IM library for iOS."
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description = "FlappyIM is a lightweight and powerful instant messaging library for iOS. It provides robust features for real-time communication, including message delivery, group chats, and more."
    
    s.homepage         = 'https://github.com/flappygod/flappyIM_ios'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'lijunlin' => '327603258@qq.com' }
    s.source           = { :git => 'https://github.com/flappygod/flappyIM_ios.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '12.0'
    
    s.source_files = 'flappyim/Classes/**/*'
    s.public_header_files = 'flappyim/Classes/Public/*.h'
    
    # s.resource_bundles = {
    #   'flappyim' => ['flappyim/Assets/*.png']
    # }
    
    s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6']
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    # s.dependency 'AFNetworking', '~> 2.3'
    s.user_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1' }
    s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1' }
    s.frameworks = 'UIKit','Foundation','AVFoundation','CoreMedia','UserNotifications','AVKit'
    s.dependency 'AFNetworking', '~> 4.0.1'
    s.dependency 'MJExtension', '~> 3.4.1'
    s.dependency 'Protobuf', '~> 3.29.5'
    s.dependency 'CocoaAsyncSocket', '~> 7.6.5'
    s.dependency 'FMDB', '~> 2.7.12'
end
