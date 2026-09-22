// swift-tools-version:5.9

// Supernotes — a notes app for iPad, built for Swift Playgrounds.
// Open this folder (Supernotes.swiftpm) directly in Swift Playgrounds on your iPad.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Supernotes",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Supernotes",
            targets: ["AppModule"],
            bundleIdentifier: "com.merta.supernotes",
            displayVersion: "1.0",
            bundleVersion: "1",
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown
            ],
            capabilities: [
                .photoLibrary(purposeString: "Supernotes uses your photo library so you can add photos as notebook pages."),
                .camera(purposeString: "Supernotes uses the camera so you can capture photos and scan documents into notebooks.")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
