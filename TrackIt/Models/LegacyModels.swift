import Foundation

struct LegacyProject: Codable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var createdAt: Date = Date()
}

struct LegacySession: Codable {
    var id: UUID = UUID()
    var title: String
    var duration: TimeInterval
    var date: Date
    var notes: String
    var projectRef: UUID?
    var status: SessionStatus // Requires SessionStatus to be visible, which it is since it's in the same module
    var voiceNoteUrl: String?
    var taskGroupRef: UUID? = nil
    var tagRefs: [UUID]? = nil
    var wasPlanned: Bool? = false
    var datePlanned: Date? = nil
}

struct LegacyTaskGroup: Codable {
    var id: UUID = UUID()
    var name: String
    var projectRef: UUID
    var createdAt: Date = Date()
    var tagRefs: [UUID]? = nil
}

struct LegacyTag: Codable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var createdAt: Date = Date()
}
