#!/bin/sh

# 1. Install Flutter
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 2. Precache and get dependencies
flutter precache --ios
flutter pub get

# 3. Install CocoaPods
cd ..
pod install
