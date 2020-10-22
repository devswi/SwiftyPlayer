Pod::Spec.new do |spec|

  spec.name         = "SwiftyPlayer"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of SwiftyPlayer."

  spec.description  = <<-DESC
                   DESC

  spec.homepage     = "https://github.com/shiwei93/SwiftyPlayer"
  spec.license      = "MIT (example)"
  spec.author             = { "shiwei93" => "stayfocusjs@gmail.com" }

  spec.source       = { :git => "https://github.com/shiwei93/SwiftyPlayer.git", :tag => "#{spec.version}" }

  spec.source_files = [
    'Source/**/*.swift',
  ]
end
