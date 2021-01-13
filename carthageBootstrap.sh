#!/bin/bash

set -e
set -o pipefail

echo "start chekout dependencies..."

carthage checkout

echo "remove ./Carthage/Checkouts/FBSimulatorControl/fbsimctl"

echo "Because we just need FBSimulatorControl.xcodeproj"

rm -rf "./Carthage/Checkouts/FBSimulatorControl/fbsimctl"


echo "start build dependencies..."

carthage build --platform Mac

echo "carthage checkout and build success."
