# Jasstafel

[![JassTafel CI](https://github.com/simonste/jasstafel/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/simonste/jasstafel/actions/workflows/build.yml?branch=main)

Jasstafel for Android & iOS (& more)

## About

Jasstafel is an app to write points in the swiss card game Jass.

| Android | Android (F-Droid) | iOS |
|:-:|:-:|:-:|
| [<img src="assets/badges/google-play-badge.png" height="50">](https://play.google.com/store/apps/details?id=ch.simonste.jasstafel) | [<img src="assets/badges/f-droid-badge.png" height="50">](https://f-droid.org/en/packages/ch.simonste.jasstafel/) | [<img src="assets/badges/appstore-badge.png" height="50">](https://apps.apple.com/ch/app/schweizer-jasstafel/id1672847164) |

## Getting Started

Generate translations:
`flutter gen-l10n`

Generate some required source files:
`flutter packages pub run build_runner build`

Run tests:
`flutter test`
`flutter test -d linux integration_test/`

Build for web:
`flutter build web`
