import Foundation

enum AppIdentity {
    static let currentBundleID = "com.swaylenserves.notescribe"
    static let legacyBundleID = "com.swaylenhayes.apps.notescribe"

    static let currentTestsBundleID = "com.swaylenserves.notescribe.tests"
    static let currentUITestsBundleID = "com.swaylenserves.notescribe.uitests"

    static let appSupportDirectoryName = currentBundleID
    static let legacyAppSupportDirectoryName = legacyBundleID
    static let customSoundsDirectoryName = "CustomSounds"
    static let legacyCustomSoundsDirectoryName = "notescribe"
    static let migrationDefaultsKey = "NoteScribeBundleIDMigrationCompleted"

    static var loggerSubsystem: String {
        Bundle.main.bundleIdentifier ?? currentBundleID
    }

    static var parakeetLoggerSubsystem: String {
        "\(loggerSubsystem).parakeet"
    }

    static var mainWindowIdentifier: String {
        "\(currentBundleID).mainWindow"
    }

    static var onboardingWindowIdentifier: String {
        "\(currentBundleID).onboardingWindow"
    }

    static var applicationSupportRootURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    static var currentAppSupportURL: URL {
        applicationSupportRootURL.appendingPathComponent(appSupportDirectoryName, isDirectory: true)
    }

    static var legacyAppSupportURL: URL {
        applicationSupportRootURL.appendingPathComponent(legacyAppSupportDirectoryName, isDirectory: true)
    }

    static var recordingsDirectoryURL: URL {
        currentAppSupportURL.appendingPathComponent("Recordings", isDirectory: true)
    }

    static var currentCustomSoundsURL: URL {
        currentAppSupportURL.appendingPathComponent(customSoundsDirectoryName, isDirectory: true)
    }

    static var legacyCustomSoundsURL: URL {
        applicationSupportRootURL
            .appendingPathComponent(legacyCustomSoundsDirectoryName, isDirectory: true)
            .appendingPathComponent(customSoundsDirectoryName, isDirectory: true)
    }
}
