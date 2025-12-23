import Foundation

// OFFLINE MODE: Minimal TranscriptionPrompt for transcription prompts only (no AI enhancement)
class TranscriptionPrompt: ObservableObject {
    @Published var transcriptionPrompt: String = ""

    private let transcriptionPromptKey = "TranscriptionPrompt"
    private let languagePromptsKeyPrefix = "LanguagePrompt_"

    init() {
        loadTranscriptionPrompt()
    }

    func updateTranscriptionPrompt() {
        let language = UserDefaults.standard.string(forKey: "SelectedLanguage") ?? "en"
        transcriptionPrompt = getLanguagePrompt(for: language)
        UserDefaults.standard.set(transcriptionPrompt, forKey: transcriptionPromptKey)
    }

    func getLanguagePrompt(for language: String) -> String {
        let key = languagePromptsKeyPrefix + language
        return UserDefaults.standard.string(forKey: key) ?? getDefaultPrompt(for: language)
    }

    func setCustomPrompt(_ prompt: String, for language: String) {
        let key = languagePromptsKeyPrefix + language
        UserDefaults.standard.set(prompt, forKey: key)

        // Update current prompt if it's for the selected language
        let selectedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage") ?? "en"
        if language == selectedLanguage {
            updateTranscriptionPrompt()
        }
    }

    private func loadTranscriptionPrompt() {
        transcriptionPrompt = UserDefaults.standard.string(forKey: transcriptionPromptKey) ?? getDefaultPrompt(for: "en")
    }

    private func getDefaultPrompt(for language: String) -> String {
        switch language {
        case "en":
            return "Hello, welcome to my lecture."
        case "es":
            return "Hola, bienvenido a mi conferencia."
        case "fr":
            return "Bonjour, bienvenue à ma conférence."
        case "de":
            return "Hallo, willkommen zu meiner Vorlesung."
        case "it":
            return "Ciao, benvenuto alla mia conferenza."
        case "pt":
            return "Olá, bem-vindo à minha palestra."
        case "nl":
            return "Hallo, welkom bij mijn lezing."
        case "pl":
            return "Cześć, witaj na moim wykładzie."
        case "ru":
            return "Здравствуйте, добро пожаловать на мою лекцию."
        case "zh":
            return "你好，欢迎来到我的讲座。"
        case "ja":
            return "こんにちは、私の講義へようこそ。"
        case "ko":
            return "안녕하세요, 제 강의에 오신 것을 환영합니다."
        case "hi":
            return "नमस्ते, मेरे व्याख्यान में आपका स्वागत है।"
        case "ar":
            return "مرحبا، مرحبا بكم في محاضرتي."
        case "tr":
            return "Merhaba, dersime hoş geldiniz."
        case "uk":
            return "Привіт, ласкаво просимо на мою лекцію."
        case "vi":
            return "Xin chào, chào mừng đến với bài giảng của tôi."
        case "id":
            return "Halo, selamat datang di kuliah saya."
        case "th":
            return "สวัสดี ยินดีต้อนรับสู่การบรรยายของฉัน"
        case "sv":
            return "Hej, välkommen till min föreläsning."
        case "no":
            return "Hei, velkommen til foredraget mitt."
        case "da":
            return "Hej, velkommen til mit foredrag."
        case "fi":
            return "Hei, tervetuloa luennolle."
        case "cs":
            return "Ahoj, vítej na mé přednášce."
        case "ro":
            return "Bună, bun venit la prelegerea mea."
        case "hu":
            return "Helló, üdvözöllek az előadásomon."
        case "el":
            return "Γεια σας, καλώς ήρθατε στη διάλεξή μου."
        case "he":
            return "שלום, ברוכים הבאים להרצאה שלי."
        case "ca":
            return "Hola, benvingut a la meva conferència."
        default:
            return "Hello, welcome to my lecture."
        }
    }
}
