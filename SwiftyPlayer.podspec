Pod::Spec.new do |spec|

  spec.name = "SwiftyPlayer"
  spec.version = "0.0.2"
  spec.summary = "A Video and Audio Player written by Swift 5."

  spec.description = <<-DESC
  A Video and Audio Player written by Swift 5. Using AVPlayer
                   DESC

  spec.homepage = "https://github.com/shiwei93/SwiftyPlayer"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author = { "shiwei93" => "stayfocusjs@gmail.com" }
  spec.platform = :ios, "10.0"

  spec.source = { :git => "https://github.com/shiwei93/SwiftyPlayer.git", :tag => "#{spec.version}" }

  spec.source_files = [
    'Source/**/*.swift',
  ]
end
