import Foundation
 
 enum PredefinedModels {
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

    // Auto-detect bundled Parakeet model at runtime
    private static var detectedModels: [any TranscriptionModel] {
        guard let bundledModelName = detectBundledParakeetModel() else {
            return []
        }

        let isV3 = bundledModelName.contains("v3")
        return [
            ParakeetModel(
                name: bundledModelName,
                displayName: isV3 ? "Parakeet V3 CoreML" : "Parakeet V2 CoreML",
                description: isV3
                    ? "NVIDIA's Parakeet V3 model (CoreML) (English and 25 European languages)."
                    : "NVIDIA's Parakeet V2 model (CoreML) (English only).",
                size: "483 MB",
                speed: 0.99,
                accuracy: 0.94,
                ramUsage: 0.8,
                supportedLanguages: getLanguageDictionary(isMultilingual: isV3, provider: .parakeet)
            )
        ]
    }

    /// Scans app bundle for a Parakeet model folder and returns the model name
    private static func detectBundledParakeetModel() -> String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let resourceURL = URL(fileURLWithPath: resourcePath)

        let modelNames = ["parakeet-tdt-0.6b-v3-coreml", "parakeet-tdt-0.6b-v2-coreml"]

        // Check all possible paths where models might be located
        let searchPaths = [
            "Parakeet",                    // New unified build: Resources/Parakeet/
            "",                            // Direct in Resources/
            "BundledModels/Parakeet"       // Legacy nested path
        ]

        for searchPath in searchPaths {
            let basePath = searchPath.isEmpty ? resourceURL : resourceURL.appendingPathComponent(searchPath)
            for modelName in modelNames {
                let modelPath = basePath.appendingPathComponent(modelName).path
                if FileManager.default.fileExists(atPath: modelPath) {
                    // Return name without -coreml suffix
                    return modelName.replacingOccurrences(of: "-coreml", with: "")
                }
            }
        }

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
