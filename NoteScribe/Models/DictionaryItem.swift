import Foundation
import SwiftUI

struct DictionaryItem: Identifiable, Hashable, Codable {
    var word: String

    var id: String { word }

    init(word: String) {
        self.word = word
    }

    private enum CodingKeys: String, CodingKey {
        case id, word, dateAdded, isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        word = try container.decode(String.self, forKey: .word)
        _ = try? container.decodeIfPresent(UUID.self, forKey: .id)
        _ = try? container.decodeIfPresent(Date.self, forKey: .dateAdded)
        _ = try? container.decodeIfPresent(Bool.self, forKey: .isEnabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
    }
}
