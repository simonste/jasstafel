# Jasstafel

[![JassTafel CI](https://github.com/simonste/jasstafel/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/simonste/jasstafel/actions/workflows/test.yml?branch=main)
[![JassTafel CD](https://github.com/simonste/jasstafel/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/simonste/jasstafel/actions/workflows/build.yml?branch=main)
[![F-Droid release](https://img.shields.io/f-droid/v/ch.simonste.jasstafel.svg?logo=F-Droid)](https://f-droid.org/en/packages/ch.simonste.jasstafel/)
[![GitHub](https://img.shields.io/github/license/simonste/jasstafel)](https://github.com/simonste/jasstafel/blob/main/LICENSE)

Jasstafel for Android & iOS (& more)

## About

Jasstafel is an app to write points in the swiss card game Jass.

| Android | Android (F-Droid) | iOS |
|:-:|:-:|:-:|
[![Google Play](assets/badges/google-play-badge.png)](https://play.google.com/store/apps/details?id=ch.simonste.jasstafel) | [![F-Droid](assets/badges/f-droid-badge.png)](https://f-droid.org/en/packages/ch.simonste.jasstafel/) | [![App Store](assets/badges/appstore-badge.png)](https://apps.apple.com/ch/app/schweizer-jasstafel/id1672847164) |

## Getting Started

The first time you might need to generate a first version of the icons:

```shell
mkdir -p android/app/src/main/res/mipmap-{hdpi,mdpi,xhdpi,xxhdpi,xxxhdpi}

for d in android/app/src/main/res/mipmap-*; do
  convert -size 1x1 xc:transparent PNG32:"$d/ic_launcher.png"
done
```

Generate translations:
`flutter gen-l10n`

Generate some required source files:
`flutter packages pub run build_runner build`

Run tests:
`flutter test`
`flutter test -d linux integration_test/`

Build for web:
`flutter build web`
