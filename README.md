<p align="center">
<a href="https://github.com/KittenYang/Longinus">
<img src="Assets/Logo.png" alt="Longinus" />
</a>
</p>
<p align="center">
  <a href="https://travis-ci.org/kittenyang@icloud.com/Longinus">
    <img src="https://img.shields.io/travis/kittenyang@icloud.com/Longinus.svg?style=for-the-badge" alt="CI Status" />
  </a>
  <a href="https://cocoapods.org/pods/Longinus">
    <img src="https://img.shields.io/cocoapods/v/Longinus.svg?style=for-the-badge"/>
  </a>
  <a href="https://cocoapods.org/pods/Longinus">
    <img src="https://img.shields.io/cocoapods/l/Longinus.svg?style=for-the-badge"/>
  </a>
  <a href="https://cocoapods.org/pods/Longinus">
    <img src="https://img.shields.io/cocoapods/p/Longinus.svg?style=for-the-badge"/>
  </a>
</p>


# Longinus
Longinus is a pure-Swift high-performance asynchronous web image loading and caching framework.

It was learned from an Objective-C web image loading framework [YYWebImage](https://github.com/ibireme/YYWebImage) and bring lots of high performace features to the Swift.

It may become a better choice for you to use a pure-Swift web image loading and caching framework.

## Feature
* Asynchronous image downloading and caching.
* Preload images and cache them to disk for further showing.
* Animated GIF support (dynamic buffer, lower memory usage).
* Baseline/progressive/interlaced image decode support.
* View extensions for UIImageView, UIButton, MKAnnotationView and CALayer to directly set an image from a URL.
* Image loading category for UIImageView, UIButton and CALayer.
* Built-in transition animation when setting images.(or you can set your custom image showing transion)
* Image Transform after downloading supported: blur, round corner, resize, color tint, crop, rotate and more.
* High performance memory and disk image cache. Use LRU algorithm to manage. For disk cache, it use file system and sqlite for better performance.
* Use FIFO queue to handle image downloading operation.
* Smooth sliding without UI lags. High performance image caching and decoding to avoid main thread blocked.

## Usage

The simplest use-case is setting an image to an image view with the UIImageView extension:
```swift
let url = URL(string: "http://github.com/logo.png")
imageView.lg.setImage(with: url)
```
Load animated gif image:
```swift
let url = URL(string: "https://ww4.sinaimg.cn/bmiddle/eaeb7349jw1ewbhiu69i2g20b4069e86.gif")
imageView.lg.setImage(with: url)
```
Load image progressively:
```swift
let url = URL(string: "http://github.com/logo.png")
imageView.lg.setImage(with: url, options: [.progressiveBlur, .imageWithFadeAnimation])
```
Load and transform image:
```swift
let url = URL(string: "https://ww4.sinaimg.cn/bmiddle/eaeb7349jw1ewbhiu69i2g20b4069e86.gif")
let transformer = ImageTransformer.imageTransformerCommon(with: imageView.frame.size, borderWidth: 2.0, borderColor: .white)
imageView.lg.setImage(with: url, options: [.progressiveBlur, .imageWithFadeAnimation], transformer: transformer)
```

# Requirements
* iOS 9.0+
* Swift 5.0+

# Installation
## CocoaPods

Longinus is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:
```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'MyApp' do
  # your other pod
  # ...
  pod 'Longinus'
end
```
Then, run the following command:

```
$ pod install
```

You should open the {Project}.xcworkspace instead of the {Project}.xcodeproj after you installed anything from CocoaPods.

For more information about how to use CocoaPods, I suggest this [tutorial](http://www.raywenderlich.com/64546/introduction-to-cocoapods-2).


## License

Longinus is available under the MIT license. See the LICENSE file for more info.

