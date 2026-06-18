import Foundation
import SwiftData

enum SessionStatus: String, Codable {
    case planned
    case running
    case completed
}

@Model
final class Project: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    
    static let defaultColors = [
        "#FF5E5B", "#D81159", "#8F2D56", "#218380", "#73D2DE",
        "#4A90E2", "#50E3C2", "#F5A623", "#B8E986", "#9013FE"
    ]
    
    init(id: UUID = UUID(), name: String, colorHex: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}

@Model
final class Session: Identifiable {
    var id: UUID
    var title: String
    var duration: TimeInterval
    var date: Date
    var notes: String
    var projectRef: UUID?
    var status: SessionStatus
    var voiceNoteUrl: String?
    var taskGroupRef: UUID?
    var tagRefs: [UUID]?
    var wasPlanned: Bool?
    var datePlanned: Date?
    
    @Transient
    var isPlannedSession: Bool {
        wasPlanned ?? false
    }
    
    init(id: UUID = UUID(), title: String, duration: TimeInterval, date: Date, notes: String, projectRef: UUID? = nil, status: SessionStatus, voiceNoteUrl: String? = nil, taskGroupRef: UUID? = nil, tagRefs: [UUID]? = nil, wasPlanned: Bool? = false, datePlanned: Date? = nil) {
        self.id = id
        self.title = title
        self.duration = duration
        self.date = date
        self.notes = notes
        self.projectRef = projectRef
        self.status = status
        self.voiceNoteUrl = voiceNoteUrl
        self.taskGroupRef = taskGroupRef
        self.tagRefs = tagRefs
        self.wasPlanned = wasPlanned
        self.datePlanned = datePlanned
    }
}

@Model
final class TaskGroup: Identifiable {
    var id: UUID
    var name: String
    var projectRef: UUID
    var createdAt: Date
    var tagRefs: [UUID]?
    
    init(id: UUID = UUID(), name: String, projectRef: UUID, createdAt: Date = Date(), tagRefs: [UUID]? = nil) {
        self.id = id
        self.name = name
        self.projectRef = projectRef
        self.createdAt = createdAt
        self.tagRefs = tagRefs
    }
}

@Model
final class Tag: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var isGroupTag: Bool
    
    static let defaultColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
    ]
    
    init(id: UUID = UUID(), name: String, colorHex: String, createdAt: Date = Date(), isGroupTag: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isGroupTag = isGroupTag
    }
}

enum AppView {
    case timer
    case workspace
}
