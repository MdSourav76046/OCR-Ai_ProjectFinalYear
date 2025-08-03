import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String?
    let gender: String?
    let createdAt: Date
    
    init(id: String, email: String, username: String, firstName: String, lastName: String, dateOfBirth: String? = nil, gender: String? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.createdAt = Date()
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let username: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String?
    let gender: String?
}

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String
} 