# beepserv
A tweak for jailbroken iPhones that can be connected with Beeper Mini to provide phone number registration functionality

## Note
This is a rewrite of the original [beepserv](https://github.com/beeper/phone-registration-provider) with some code from the original.

The tweak is now split into 4 parts:
- **Application**: An app that shows the registration code, logs, and allows state notifications to be turned on or off
- **Controller**: A launch daemon that manages basically everything, including the relay connection
- **NotificationHelper**: This hooks into `SpringBoard` and sends local notifications
- **IdentityServices**: The part that hooks into `identityservicesd` and handles the generation of validation data

The app is pretty simple and does not have an icon yet.

## Building
You need to have [Theos](https://theos.dev/docs/installation) installed.

Also make sure Theos is up-to-date by running `$THEOS/bin/update-theos` (or `make update-theos`).

### Rootful
`make clean package FINALPACKAGE=1`

The Makefiles currently assume you have Xcode 11.7 installed at `/Applications/Xcode_11.7.app` when packaging for rootful to ensure compatibility with A12+ devices on iOS 12.0-13.7 ([more here](https://theos.dev/docs/arm64e-deployment)). You can either download this version from Apple or edit the Makefiles if you want to build with a different version.

### Rootless
`make clean package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1`

## Usage
This tweak should automatically run in the background, connected to Beeper's relay service, available to facilitate registering your Android's phone number with Apple.

To start this registration process, open the beepserv app, and enter the displayed registration code into Beeper Mini, and it should automatically start the registration process.

If you cannot find the code, SSH into the device and run `cat /var/mobile/.beepserv_state` (rootful) or `cat /var/jb/var/mobile/.beepserv_state` (rootless) to view the registration code.