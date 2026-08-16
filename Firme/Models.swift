import Foundation
import SwiftData

@Model
class UserProfile {
    var passwordHash: String
    var userMessage: String
    var timerDuration: Int
    var createdAt: Date
    
    init(passwordHash: String, userMessage: String, timerDuration: Int = 120) {
        self.passwordHash = passwordHash
        self.userMessage = userMessage
        self.timerDuration = timerDuration
        self.createdAt = Date()
    }
}

@Model
class PauseAttempt {
    var site: String
    var timestamp: Date
    var wentForHelp: Bool
    
    init(site: String, timestamp: Date = Date(), wentForHelp: Bool = false) {
        self.site = site
        self.timestamp = timestamp
        self.wentForHelp = wentForHelp
    }
}

@Model
class CustomSite {
    var domain: String
    var addedAt: Date
    
    init(domain: String, addedAt: Date = Date()) {
        self.domain = domain
        self.addedAt = addedAt
    }
}

@Model
class FallLog {
    var date: Date
    
    init(date: Date = Date()) {
        self.date = date
    }
}

// Hashing simple para no guardar la clave en texto plano
import CryptoKit

func hashPassword(_ password: String) -> String {
    let data = Data(password.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
