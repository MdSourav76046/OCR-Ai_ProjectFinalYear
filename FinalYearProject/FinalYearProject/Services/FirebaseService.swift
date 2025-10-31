import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private var db: Firestore?
    private var storage: Storage?
    
    private init() {
        if FirebaseApp.app() != nil {
            db = Firestore.firestore()
            storage = Storage.storage()
        }
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, username: String, firstName: String, lastName: String, dateOfBirth: String?, gender: String?) async throws -> User {
        guard FirebaseApp.app() != nil else {
            throw FirebaseError.userNotFound
        }
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let user = User(
            id: result.user.uid,
            email: email,
            username: username,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            gender: gender
        )
        
        try await saveUserToFirestore(user)
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        
        let user = try await getUserFromFirestore(userId: result.user.uid)
        return user
    }
    
    @MainActor func signOut() throws {
        try Auth.auth().signOut()
        // Also sign out from Google if user was signed in with Google
        GoogleSignInService.shared.signOut()
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            username: firebaseUser.displayName ?? "",
            firstName: "",
            lastName: "",
            dateOfBirth: nil,
            gender: nil
        )
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async throws -> User {
        let authResult = try await GoogleSignInService.shared.signIn()
        
        // Check if user exists in Firestore
        do {
            let user = try await getUserFromFirestore(userId: authResult.user.uid)
            return user
        } catch {
            // User doesn't exist in Firestore, create new user
            let user = User(
                id: authResult.user.uid,
                email: authResult.user.email ?? "",
                username: authResult.user.displayName ?? "",
                firstName: authResult.user.displayName ?? "",
                lastName: "",
                dateOfBirth: nil,
                gender: nil
            )
            
            try await saveUserToFirestore(user)
            return user
        }
    }
    
    // MARK: - Firestore Operations
    private func saveUserToFirestore(_ user: User) async throws {
        guard let db = db else {
            throw FirebaseError.userNotFound
        }
        
        let userData: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "dateOfBirth": user.dateOfBirth ?? "",
            "gender": user.gender ?? "",
            "createdAt": Timestamp(date: user.createdAt)
        ]
        
        try await db.collection("users").document(user.id).setData(userData)
    }
    
    func getUserFromFirestore(userId: String) async throws -> User {
        guard let db = db else {
            throw FirebaseError.userNotFound
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else {
            throw FirebaseError.userNotFound
        }
        
        return User(
            id: data["id"] as? String ?? "",
            email: data["email"] as? String ?? "",
            username: data["username"] as? String ?? "",
            firstName: data["firstName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            dateOfBirth: data["dateOfBirth"] as? String,
            gender: data["gender"] as? String
        )
    }
    
    // MARK: - Document Upload
    func uploadDocument(imageData: Data, fileName: String) async throws -> String {
        let storageRef = storage?.reference().child("documents/\(UUID().uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef!.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef!.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Document History
    func saveDocumentToHistory(document: Document) async throws {
        let documentData: [String: Any] = [
            "id": document.id,
            "fileName": document.fileName,
            "fileType": document.fileType.rawValue,
            "conversionType": document.conversionType.rawValue,
            "outputFormat": document.outputFormat.rawValue,
            "status": document.status.rawValue,
            "createdAt": Timestamp(date: document.createdAt),
            "userId": Auth.auth().currentUser?.uid ?? ""
        ]
        
        try await db?.collection("documents").document(document.id).setData(documentData)
    }
    
    func getDocumentHistory() async throws -> [Document] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseError.userNotFound
        }
        
        let snapshot = try await db?.collection("documents")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot!.documents.map { document in
            let data = document.data()
            return Document(
                id: data["id"] as? String ?? "",
                fileName: data["fileName"] as? String ?? "",
                fileType: DocumentType(rawValue: data["fileType"] as? String ?? "") ?? .image,
                conversionType: ConversionType(rawValue: data["conversionType"] as? String ?? "") ?? .cameraToPdf,
                outputFormat: OutputFormat(rawValue: data["outputFormat"] as? String ?? "") ?? .pdf,
                status: ProcessingStatus(rawValue: data["status"] as? String ?? "") ?? .pending
            )
        }
    }
    
    // MARK: - User Profile Operations
    func updateUserProfile(
        firstName: String,
        lastName: String,
        username: String,
        dateOfBirth: String?,
        gender: String?
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseError.userNotFound
        }
        
        // Always save to local storage first (fast and guaranteed)
        saveProfileToLocalStorage(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            username: username,
            dateOfBirth: dateOfBirth,
            gender: gender
        )
        
        // Try to update Firestore if available (with timeout to prevent hanging)
        if let db = db {
            do {
                let userData: [String: Any] = [
                    "firstName": firstName,
                    "lastName": lastName,
                    "username": username,
                    "dateOfBirth": dateOfBirth ?? "",
                    "gender": gender ?? ""
                ]
                
                // Add timeout to prevent hanging if Firestore is not set up
                try await withTimeout(seconds: 2) {
                    try await db.collection("users").document(userId).updateData(userData)
                }
                print("✅ Profile saved to Firestore")
            } catch {
                // If Firestore fails (database not set up or timeout), that's OK - we already saved locally
                print("⚠️ Firestore update failed: \(error.localizedDescription)")
                print("📝 Profile saved to local storage instead")
            }
        }
    }
    
    // MARK: - Timeout Helper for Firestore Operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw FirebaseError.firestoreNotAvailable
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Local Storage Fallback
    private func saveProfileToLocalStorage(
        userId: String,
        firstName: String,
        lastName: String,
        username: String,
        dateOfBirth: String?,
        gender: String?
    ) {
        let defaults = UserDefaults.standard
        let key = "user_profile_\(userId)"
        
        let profileData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "username": username,
            "dateOfBirth": dateOfBirth ?? "",
            "gender": gender ?? ""
        ]
        
        defaults.set(profileData, forKey: key)
        print("✅ Profile saved to local storage")
    }
    
    // MARK: - Load Profile from Local Storage
    func loadProfileFromLocalStorage(userId: String) -> [String: String]? {
        let defaults = UserDefaults.standard
        let key = "user_profile_\(userId)"
        
        if let profileData = defaults.dictionary(forKey: key) as? [String: String] {
            return profileData
        }
        
        return nil
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            throw FirebaseError.userNotFound
        }
        
        // Re-authenticate user with current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        
        // Update password
        try await user.updatePassword(to: newPassword)
    }
}

enum FirebaseError: Error, LocalizedError {
    case userNotFound
    case uploadFailed
    case downloadFailed
    case invalidCredentials
    case passwordUpdateFailed
    case firestoreNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .uploadFailed:
            return "Failed to upload document"
        case .downloadFailed:
            return "Failed to download document"
        case .invalidCredentials:
            return "Invalid current password"
        case .passwordUpdateFailed:
            return "Failed to update password"
        case .firestoreNotAvailable:
            return "Firestore database is not set up. Profile saved locally."
        }
    }
} 
