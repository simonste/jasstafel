#!/bin/bash

# Yearly refresh: delete ios_distribution.cer & run this script
#
# Per Developer Profile:
# - Create Certificate of type iOS Distribution @ https://developer.apple.com/account/resources/certificates/list"
# Per App:
# - Create Profile of type App Store Connect @ https://developer.apple.com/account/resources/profiles/list"


# GithubActions: 
# - https://medium.com/team-rockstars-it/the-easiest-way-to-build-a-flutter-ios-app-using-github-actions-plus-a-key-takeaway-for-developers-48cf2ad7c72a
# - https://github.com/damienaicheh/demo_flutter_github_actions
# - https://stackoverflow.com/questions/71635866/build-ipa-file-in-flutter-using-github-actions
# - https://www.cobeisfresh.com/blog/how-to-implement-a-ci-cd-workflow-for-ios-using-github-actions
# - https://docs.github.com/en/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development

# Generate Private Key: 
# - https://gist.github.com/rlanyi/f3edad3bd2f1753a937f8a0c6182d55a
# - https://stackoverflow.com/questions/70431528/mac-verification-failed-during-pkcs12-import-wrong-password-azure-devops

if [ ! -f "pkpass.csr" ]; then
    echo "Generate Private Key (leave password empty!)"
    # Leave password empty
    openssl genrsa -out pkpass.key 2048
    openssl req -new -key pkpass.key -out pkpass.csr
fi

mkdir -p "res"

if [ ! -f "res/AppleWWDRCA.cer" ]; then
    echo "Download Apple certificate"
    cd res
    wget --quiet http://developer.apple.com/certificationauthority/AppleWWDRCA.cer
    openssl x509 -inform der -in AppleWWDRCA.cer -out AppleWWDRCA.pem
    cd ..
fi

# This has to be refreshed after 1 year
if [ ! -f "ios_distribution.cer" ]; then
    rm res/ios_distribution.pem
    rm jasstafel_distribution.mobileprovision
    echo "FAIL: ios_distribution certificate missing"
    echo "Create Certificate of type iOS Distribution @ https://developer.apple.com/account/resources/certificates/list"
    echo "Download it to ios_distribution.cer"
    exit
fi

if [ ! -f "res/ios_distribution.pem" ]; then
    rm ios_distribution.p12
    echo "Prepare ios_distribution certificate"
    openssl x509 -inform der -in ios_distribution.cer -out res/ios_distribution.pem
fi

if [ ! -f "ios_distribution.p12" ]; then
    echo "Create P12 file"
    echo "Use Password from Password Safe (Apple Developer)"
    openssl pkcs12 -export -legacy -clcerts -inkey pkpass.key -in res/ios_distribution.pem -certfile res/AppleWWDRCA.pem -name "Simon Steinmann" -out ios_distribution.p12
fi

if [ ! -f "jasstafel_distribution.mobileprovision" ]; then
    echo "FAIL: App Store Provision profile missing"
    echo "Create Profile of type App Store Connect @ https://developer.apple.com/account/resources/profiles/list"
    echo "Name it 'jasstafel_distribution and Download it to jasstafel_distribution.mobileprovision"
    exit
fi

if [ ! -f "AuthKey.p8" ]; then
    echo "FAIL: App Store API Key missing"
    echo "create Key @https://appstoreconnect.apple.com/access/api"
    echo "Download it as AuthKey.p8"
    exit
fi

base64 -i ios_distribution.p12 | xsel
read -p 'P12_BASE64 copied to clipboard ...'

base64 -i jasstafel_distribution.mobileprovision | xsel
read -p 'BUILD_PROVISION_PROFILE_BASE64 copied to clipboard ...'

base64 -i AuthKey.p8 | xsel
read -p 'APPSTORE_API_PRIVATE_KEY_BASE64 copied to clipboard ...'

