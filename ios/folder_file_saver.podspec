#
# CocoaPods spec, used by apps that have not switched to Swift Package Manager.
# Run `pod lib lint folder_file_saver.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'folder_file_saver'
  s.version          = '3.1.0'
  s.summary          = 'Save files into the Photos library or a folder named after your app.'
  s.description      = <<-DESC
Save images and videos to the Photos library, and other files to a folder named
after your app that shows up in the Files app.
                       DESC
  s.homepage         = 'https://github.com/bonamoogy/FolderFileSaver'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'bonamoogy' => 'https://github.com/bonamoogy' }
  s.source           = { :path => '.' }
  s.source_files     = 'folder_file_saver/Sources/folder_file_saver/**/*.swift'
  s.resource_bundles = { 'folder_file_saver_privacy' => ['folder_file_saver/Sources/folder_file_saver/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.frameworks       = 'Photos'
  s.platform         = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
