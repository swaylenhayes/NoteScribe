import Foundation

// v1.2: Only Parakeet V3 model supported
extension TranscriptionState {
    var usableModels: [any TranscriptionModel] {
        allAvailableModels.filter { model in
            switch model.provider {
            case .local:
                // v1.2: No local Transcription models
                return false
            case .parakeet:
                return isParakeetModelDownloaded(named: model.name)
            }
        }
    }
} 
