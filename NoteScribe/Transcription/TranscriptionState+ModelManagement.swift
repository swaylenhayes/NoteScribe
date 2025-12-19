import Foundation
import SwiftUI

@MainActor
extension TranscriptionState {
    // Loads the default transcription model from UserDefaults
    func loadCurrentTranscriptionModel() {
        if let savedModelName = UserDefaults.standard.string(forKey: "CurrentTranscriptionModel"),
           let savedModel = allAvailableModels.first(where: { $0.name == savedModelName }) {
            currentTranscriptionModel = savedModel
        } else if let defaultModel = allAvailableModels.first {
            // v1.2: Auto-select Parakeet V3 if no model is set (first launch)
            setDefaultTranscriptionModel(defaultModel)
        }
    }

    // Function to set any transcription model as default
    func setDefaultTranscriptionModel(_ model: any TranscriptionModel) {
        self.currentTranscriptionModel = model
        UserDefaults.standard.set(model.name, forKey: "CurrentTranscriptionModel")

        // v1.2: Only Parakeet V3 - always ready to use
        self.isModelLoaded = true

        // Post notification about the model change
        NotificationCenter.default.post(name: .didChangeModel, object: nil, userInfo: ["modelName": model.name])
        NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
    }
    
    func refreshAllAvailableModels() {
        let currentModelName = currentTranscriptionModel?.name
        let models = PredefinedModels.models

        // v1.2: No local Transcription models - only Parakeet V3 from PredefinedModels

        allAvailableModels = models

        // Preserve current selection by name (IDs may change for dynamic models)
        if let currentName = currentModelName,
           let updatedModel = allAvailableModels.first(where: { $0.name == currentName }) {
            setDefaultTranscriptionModel(updatedModel)
        } else if currentTranscriptionModel == nil, let defaultModel = allAvailableModels.first {
            // v1.2: Auto-select Parakeet V3 if no model is currently set
            setDefaultTranscriptionModel(defaultModel)
        }
    }
} 
