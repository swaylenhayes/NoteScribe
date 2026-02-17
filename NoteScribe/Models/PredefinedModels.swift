import Foundation
 
enum PredefinedModels {
    private static let fileManager = FileManager.default
    private static let parakeetModelCandidates: [(folderName: String, relativePath: String)] = [
        ("parakeet-tdt-0.6b-v3-coreml", "parakeet-v3/parakeet-tdt-0.6b-v3-coreml"),
        ("parakeet-tdt-0.6b-v2-coreml", "parakeet-v2/parakeet-tdt-0.6b-v2-coreml")
    ]

    static func getLanguageDictionary(isMultilingual: Bool, provider: ModelProvider = .local) -> [String: String] {
        if !isMultilingual {
            return ["en": "English"]
        } else {
            return allLanguages
        }
    }
    
    // OFFLINE MODE: Only return pre-bundled models, no custom models
    static var models: [any TranscriptionModel] {
        return detectedModels
    }

    // Auto-detect available Parakeet models at runtime
    private static var detectedModels: [any TranscriptionModel] {
        let availableModelNames = Set(detectAvailableParakeetModels())

        return parakeetModelCandidates.compactMap { candidate in
            let normalizedName = candidate.folderName.replacingOccurrences(of: "-coreml", with: "")
            guard availableModelNames.contains(normalizedName) else { return nil }

            let isV3 = normalizedName.contains("v3")
            return ParakeetModel(
                name: normalizedName,
                displayName: isV3 ? "Parakeet V3 CoreML" : "Parakeet V2 CoreML",
                description: isV3
                    ? "NVIDIA's Parakeet V3 model (CoreML) (English and 25 European languages)."
                    : "NVIDIA's Parakeet V2 model (CoreML) (English only).",
                size: "483 MB",
                speed: isV3 ? 0.99 : 1.0,
                accuracy: isV3 ? 0.94 : 0.92,
                ramUsage: 0.8,
                supportedLanguages: getLanguageDictionary(isMultilingual: isV3, provider: .parakeet)
            )
        }
    }

    /// Scans app bundle first, then local dev models directory, for all available Parakeet model folders.
    private static func detectAvailableParakeetModels() -> [String] {
        var bundledModels: [String] = []

        if let resourcePath = Bundle.main.resourcePath {
            bundledModels = detectBundledParakeetModels(in: URL(fileURLWithPath: resourcePath))
        }

        let chosenModels: [String]
        if !bundledModels.isEmpty {
            chosenModels = bundledModels
        } else {
            chosenModels = detectDeveloperParakeetModels()
        }

        return chosenModels.map { $0.replacingOccurrences(of: "-coreml", with: "") }
    }

    private static func detectBundledParakeetModels(in resourcesDir: URL) -> [String] {
        let searchPaths = [
            "Parakeet",
            "",
            "BundledModels/Parakeet"
        ]

        return parakeetModelCandidates.compactMap { candidate in
            for searchPath in searchPaths {
                let basePath = searchPath.isEmpty ? resourcesDir : resourcesDir.appendingPathComponent(searchPath)
                let modelPath = basePath.appendingPathComponent(candidate.folderName, isDirectory: true)
                if hasRequiredParakeetFiles(at: modelPath) {
                    return candidate.folderName
                }
            }
            return nil
        }
    }

    private static func detectDeveloperParakeetModels() -> [String] {
        guard let modelsDir = developerModelsDirectory else { return [] }

        return parakeetModelCandidates.compactMap { candidate in
            let modelPath = modelsDir.appendingPathComponent(candidate.relativePath, isDirectory: true)
            return hasRequiredParakeetFiles(at: modelPath) ? candidate.folderName : nil
        }
    }

    private static func hasRequiredParakeetFiles(at modelPath: URL) -> Bool {
        let requiredDirectories = [
            "Encoder.mlmodelc",
            "Decoder.mlmodelc",
            "JointDecision.mlmodelc",
            "Preprocessor.mlmodelc"
        ]
        let hasCoreModels = requiredDirectories.allSatisfy {
            fileManager.fileExists(atPath: modelPath.appendingPathComponent($0, isDirectory: true).path)
        }

        let vocabFiles = ["parakeet_v3_vocab.json", "parakeet_vocab.json"]
        let hasVocab = vocabFiles.contains {
            fileManager.fileExists(atPath: modelPath.appendingPathComponent($0).path)
        }

        return hasCoreModels && hasVocab
    }

    private static var developerModelsDirectory: URL? {
        if let configuredPath = ProcessInfo.processInfo.environment["NOTESCRIBE_MODELS_DIR"],
           !configuredPath.isEmpty {
            let configuredURL = URL(fileURLWithPath: configuredPath, isDirectory: true)
            if fileManager.fileExists(atPath: configuredURL.path) {
                return configuredURL
            }
        }

        #if DEBUG
        var current = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = current.appendingPathComponent("models", isDirectory: true)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                break
            }
            current = parent
        }
        #endif

        return nil
    }
 
     static let allLanguages = [
         "auto": "Auto-detect",
         "af": "Afrikaans",
         "am": "Amharic",
         "ar": "Arabic",
         "as": "Assamese",
         "az": "Azerbaijani",
         "ba": "Bashkir",
         "be": "Belarusian",
         "bg": "Bulgarian",
         "bn": "Bengali",
         "bo": "Tibetan",
         "br": "Breton",
         "bs": "Bosnian",
         "ca": "Catalan",
         "cs": "Czech",
         "cy": "Welsh",
         "da": "Danish",
         "de": "German",
         "el": "Greek",
         "en": "English",
         "es": "Spanish",
         "et": "Estonian",
         "eu": "Basque",
         "fa": "Persian",
         "fi": "Finnish",
         "fo": "Faroese",
         "fr": "French",
         "gl": "Galician",
         "gu": "Gujarati",
         "ha": "Hausa",
         "haw": "Hawaiian",
         "he": "Hebrew",
         "hi": "Hindi",
         "hr": "Croatian",
         "ht": "Haitian Creole",
         "hu": "Hungarian",
         "hy": "Armenian",
         "id": "Indonesian",
         "is": "Icelandic",
         "it": "Italian",
         "ja": "Japanese",
         "jw": "Javanese",
         "ka": "Georgian",
         "kk": "Kazakh",
         "km": "Khmer",
         "kn": "Kannada",
         "ko": "Korean",
         "la": "Latin",
         "lb": "Luxembourgish",
         "ln": "Lingala",
         "lo": "Lao",
         "lt": "Lithuanian",
         "lv": "Latvian",
         "mg": "Malagasy",
         "mi": "Maori",
         "mk": "Macedonian",
         "ml": "Malayalam",
         "mn": "Mongolian",
         "mr": "Marathi",
         "ms": "Malay",
         "mt": "Maltese",
         "my": "Myanmar",
         "ne": "Nepali",
         "nl": "Dutch",
         "nn": "Norwegian Nynorsk",
         "no": "Norwegian",
         "oc": "Occitan",
         "pa": "Punjabi",
         "pl": "Polish",
         "ps": "Pashto",
         "pt": "Portuguese",
         "ro": "Romanian",
         "ru": "Russian",
         "sa": "Sanskrit",
         "sd": "Sindhi",
         "si": "Sinhala",
         "sk": "Slovak",
         "sl": "Slovenian",
         "sn": "Shona",
         "so": "Somali",
         "sq": "Albanian",
         "sr": "Serbian",
         "su": "Sundanese",
         "sv": "Swedish",
         "sw": "Swahili",
         "ta": "Tamil",
         "te": "Telugu",
         "tg": "Tajik",
         "th": "Thai",
         "tk": "Turkmen",
         "tl": "Tagalog",
         "tr": "Turkish",
         "tt": "Tatar",
         "uk": "Ukrainian",
         "ur": "Urdu",
         "uz": "Uzbek",
         "vi": "Vietnamese",
         "yi": "Yiddish",
         "yo": "Yoruba",
         "yue": "Cantonese",
         "zh": "Chinese",
     ]
 }
