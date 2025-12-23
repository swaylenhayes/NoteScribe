import Foundation

// v1.2: Only Parakeet V3 model supported
extension TranscriptionState {
    var usableModels: [any TranscriptionModel] {
        allAvailableModels.filter { model in
            isParakeetModelDownloaded(named: model.name)
        }
    }
} 
