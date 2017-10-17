# PASTA
A Swift SDK to detect passive Tangibles on capacitive screens.

<!--[![CI Status](http://img.shields.io/travis/Aaron Krämer/PASTA.svg?style=flat)](https://travis-ci.org/Aaron Krämer/PASTA)-->
[![Version](https://img.shields.io/cocoapods/v/PASTA.svg?style=flat)](http://cocoapods.org/pods/PASTA)
[![License](https://img.shields.io/cocoapods/l/PASTA.svg?style=flat)](http://cocoapods.org/pods/PASTA)
[![Platform](https://img.shields.io/cocoapods/p/PASTA.svg?style=flat)](http://cocoapods.org/pods/PASTA)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

PASTA is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PASTA'
```

## How To Use

To use PASTA in your project:
1. ``import PASTA``
2. Add an instance of ``PASTAView`` as a subview or set it as type of a view in Interface Builder.
3. Implement ``TangibleEvent`` and assign the object to ``tangibleDelegate`` property of ``PASTAView``.
4. Provide some patterns by calling ``whitelist(pattern:identifier:)``

	4.1. Create ``PASTAPattern`` with ``MarkerSnapshot`` from scratch, or

	4.2. disable whitelist by setting ``patternWhitelistDisabled`` to ``true``, place your desired Tangibles on the screen, whitelist the patterns, and enable whitelist again.

## Tangibles

A design and instructions on how to build a tangible are available at [Thingiverse](https://www.thingiverse.com/thing:1810704)

## Author

Aaron Krämer

## License

PASTA is available under the MIT license. See the LICENSE file for more info.
