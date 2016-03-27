Pod::Spec.new do |s|
  s.name             = "PushReview"
  s.version          = "0.2.2"
  s.summary          = "New unobtrusive way of asking users to leave a review on the App Store."
  s.description      = <<-DESC
                       PushReview is a library aimed at getting your app the reviews it deserves. It asks users for an App Store review when they are done using the app and are in an idle state.
                       DESC
  s.homepage         = "https://github.com/gapl/PushReview"
  s.license          = 'MIT'
  s.author           = { "Gasper Kolenc" => "kolenc.gasper@gmail.com" }
  s.source           = { :git => "https://github.com/gapl/PushReview.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Source/*.swift'
end
