Pod::Spec.new do |spec|

  spec.name = "SwiftyPlayer"
  spec.version = "0.0.2"
  spec.summary = "A Swift libray for stream video and audio player."

  spec.description = <<-DESC
  A video and audio Player written by Swift 5, on top of AVPlayer.
                   DESC

  spec.homepage = "https://github.com/shiwei93/SwiftyPlayer"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author = { "shiwei93" => "stayfocusjs@gmail.com" }
  spec.platform = :ios, "10.0"
  spec.swift_versions = '5.3'

  spec.source = { :git => "https://github.com/shiwei93/SwiftyPlayer.git", :tag => "#{spec.version}" }

  spec.source_files = [
    'Sources/**/*.swift',
  ]
end
