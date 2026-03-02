import Foundation
import os.log

enum AppDataMigrationService {
    private static let logger = Logger(subsystem: AppIdentity.currentBundleID, category: "AppDataMigration")

    static func migrateIfNeeded() {
        if migrationCompleted {
            return
        }

        var encounteredConflict = false

        do {
            try migrateLegacyDefaults()
        } catch {
            logger.error("UserDefaults migration failed: \(error.localizedDescription)")
            return
        }

        do {
            if try moveItemIfNeeded(
                from: AppIdentity.legacyAppSupportURL,
                to: AppIdentity.currentAppSupportURL,
                label: "Application Support directory"
            ) == .conflict {
                encounteredConflict = true
            }
        } catch {
            logger.error("Application Support migration failed: \(error.localizedDescription)")
            return
        }

        do {
            if try moveItemIfNeeded(
                from: AppIdentity.legacyCustomSoundsURL,
                to: AppIdentity.currentCustomSoundsURL,
                label: "custom sounds directory"
            ) == .conflict {
                encounteredConflict = true
            }
        } catch {
            logger.error("Custom sounds migration failed: \(error.localizedDescription)")
            return
        }

        guard !encounteredConflict else {
            logger.warning("Migration left unresolved conflicts; completion marker not written")
            return
        }

        markMigrationCompleted()
    }

    private static var migrationCompleted: Bool {
        let currentDomain = UserDefaults.standard.persistentDomain(forName: AppIdentity.currentBundleID) ?? [:]
        return (currentDomain[AppIdentity.migrationDefaultsKey] as? Bool) == true
    }

    private static func markMigrationCompleted() {
        var currentDomain = UserDefaults.standard.persistentDomain(forName: AppIdentity.currentBundleID) ?? [:]
        currentDomain[AppIdentity.migrationDefaultsKey] = true
        UserDefaults.standard.setPersistentDomain(currentDomain, forName: AppIdentity.currentBundleID)
        logger.info("Bundle identifier migration marked complete")
    }

    private static func migrateLegacyDefaults() throws {
        let defaults = UserDefaults.standard
        guard let legacyDomain = defaults.persistentDomain(forName: AppIdentity.legacyBundleID), !legacyDomain.isEmpty else {
            return
        }

        let currentDomain = defaults.persistentDomain(forName: AppIdentity.currentBundleID) ?? [:]
        let merged = legacyDomain.merging(currentDomain) { _, current in current }
        defaults.setPersistentDomain(merged, forName: AppIdentity.currentBundleID)
        logger.info("Migrated legacy defaults into new bundle domain")
    }

    @discardableResult
    private static func moveItemIfNeeded(from sourceURL: URL, to destinationURL: URL, label: String) throws -> MigrationMoveResult {
        let fileManager = FileManager.default
        let sourceExists = fileManager.fileExists(atPath: sourceURL.path)
        let destinationExists = fileManager.fileExists(atPath: destinationURL.path)

        guard sourceExists else {
            return .notNeeded
        }

        if destinationExists {
            logger.warning("Both legacy and current \(label, privacy: .public) exist; leaving both in place")
            return .conflict
        }

        try fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
        logger.info("Moved legacy \(label, privacy: .public) to new location")
        return .migrated
    }
}

private enum MigrationMoveResult {
    case notNeeded
    case migrated
    case conflict
}
