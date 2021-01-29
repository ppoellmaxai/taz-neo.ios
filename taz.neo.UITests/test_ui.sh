#!/bin/bash

#jq necessary to read config
if ! jq --version &> /dev/null
then
    if [[ "$OSTYPE" == "darwin"* ]]; then brew install jq
    else echo "xcodebuild is only supported on Mac OS"
    fi
fi

platform='test'
config_file="./device_settings.json"
platform="$( jq -r '.platform' $config_file )"
device_name="$( jq -r ".name" $config_file )"


if [ "$platform" = "iOS Simulator" ]
then
    xcrun simctl shutdown all && xcrun simctl erase all
    xcodebuild \
        -project ../taz.neo.xcodeproj/ \
        -scheme "taz.neo" \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,name=${device_name}"\
        clean test
elif [ "$platform" = 'iOS' ]
then
    xcodebuild \
            -project ../taz.neo.xcodeproj/ \
            -scheme "taz.neo" \
            -destination "platform=iOS,name=${device_name}"\
            clean test
else    
    echo "Platform must bei one of 'iOS Simluator' or 'iOS'"
fi