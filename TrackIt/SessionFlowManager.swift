//
//  SessionFlowManager.swift
//  TrackIt
//
//  Created by Antigravity on 6/3/26.
//

import SwiftUI
import Combine

enum SessionStatus: String, Codable {
    case planned
    case running
    case completed
}

struct Project: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var createdAt: Date = Date()
    
    static let defaultColors = [
        "#FF5E5B", "#D81159", "#8F2D56", "#218380", "#73D2DE",
        "#4A90E2", "#50E3C2", "#F5A623", "#B8E986", "#9013FE"
    ]
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorHex, createdAt
    }
    
    init(id: UUID = UUID(), name: String, colorHex: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.colorHex = try container.decode(String.self, forKey: .colorHex)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct Session: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var duration: TimeInterval // completed duration
    var date: Date
    var notes: String
    var projectRef: UUID?
    var status: SessionStatus
    var voiceNoteUrl: String?
    var taskGroupRef: UUID? = nil
    
    // Compatibility-safe fields for chronological timeline tracking
    var wasPlanned: Bool? = false
    var datePlanned: Date? = nil
    
    var isPlannedSession: Bool {
        wasPlanned ?? false
    }
}

struct TaskGroup: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var projectRef: UUID
    var createdAt: Date = Date()
}

enum AppView {
    case timer
    case workspace
}

@Observable
class SessionFlowManager {
    // Timer State
    var timerDuration: TimeInterval = 0  // 0 means count-up, >0 means countdown
    var timeElapsed: TimeInterval = 0
    var isRunning: Bool = false
    var inputTimerText: String = ""
    var parseFeedback: String? = nil
    var feedbackColor: Color = .green
    
    // Core Data Lists
    var sessions: [Session] = []
    var projects: [Project] = []
    var taskGroups: [TaskGroup] = []
    
    // UI Navigation State
    var currentView: AppView = .timer
    var showSaveSheet: Bool = false
    var timerTypeString: String = "Stopwatch" // "Countdown" or "Stopwatch"
    var isCompactMode: Bool = false
    var activeSessionId: UUID? = nil
    
    // Private Timer Helpers
    private var timer: Timer? = nil
    private var startDate: Date? = nil
    private var accumulatedTime: TimeInterval = 0
    
    init() {
        loadData()
        // Seed initial projects if empty
        if projects.isEmpty {
            projects = [
                Project(name: "Fleet Management App", colorHex: "#4A90E2"),
                Project(name: "UniMart", colorHex: "#50E3C2"),
                Project(name: "SmartQueue", colorHex: "#F5A623")
            ]
            saveData()
        }
    }
    
    // MARK: - Timer Controls
    
    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func pauseTimer() {
        guard isRunning else { return }
        isRunning = false
        if let start = startDate {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        timer?.invalidate()
        timer = nil
    }
    
    func resumeTimer() {
        startTimer()
    }
    
    func resetTimer() {
        pauseTimer()
        accumulatedTime = 0
        timeElapsed = 0
        // If there was an active planned session running, revert its status to .planned
        if let activeId = activeSessionId {
            if let index = sessions.firstIndex(where: { $0.id == activeId }) {
                sessions[index].status = .planned
                saveData()
            }
            activeSessionId = nil
        }
        timerDuration = 0
    }
    
    func startPlannedSession(_ session: Session) {
        activeSessionId = session.id
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index].status = .running
            saveData()
        }
        startTimer()
    }
    
    func stopAndPromptSave() {
        pauseTimer()
        // Save the elapsed time
        let durationToSave = timeElapsed
        if durationToSave > 0 {
            showSaveSheet = true
        } else {
            resetTimer()
        }
    }
    
    private func updateTimer() {
        guard let start = startDate else { return }
        let currentElapsed = Date().timeIntervalSince(start) + accumulatedTime
        
        if timerDuration > 0 {
            // Countdown Mode
            if currentElapsed >= timerDuration {
                timeElapsed = timerDuration
                pauseTimer()
                // Auto trigger save/completion when countdown finishes
                showSaveSheet = true
            } else {
                timeElapsed = currentElapsed
            }
        } else {
            // Count-up Mode
            timeElapsed = currentElapsed
        }
    }
    
    var timeRemaining: TimeInterval {
        if timerDuration > 0 {
            return max(0, timerDuration - timeElapsed)
        } else {
            return timeElapsed
        }
    }
    
    // MARK: - Natural Language Parsing
    
    func submitTimerInput() {
        let text = inputTimerText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputTimerText = ""
        
        guard !text.isEmpty else { return }
        
        if let parsedResult = parseDuration(text) {
            let parsedSecs = parsedResult.duration
            
            if parsedResult.isAddition {
                if timerDuration == 0 && timeElapsed > 0 {
                    // Currently stopwatch mode, convert to countdown? 
                    // Let's add to current elapsed to start a countdown
                    timerDuration = timeElapsed + parsedSecs
                } else {
                    timerDuration += parsedSecs
                }
                showFeedback("Added \(formatFeedbackTime(parsedSecs))", color: .green)
            } else if parsedResult.isSubtraction {
                if timerDuration > 0 {
                    timerDuration = max(0, timerDuration - parsedSecs)
                    showFeedback("Subtracted \(formatFeedbackTime(parsedSecs))", color: .orange)
                } else {
                    showFeedback("Cannot subtract from Stopwatch", color: .red)
                }
            } else {
                // Set duration
                timerDuration = parsedSecs
                resetTimer()
                showFeedback("Timer set to \(formatFeedbackTime(parsedSecs))", color: .green)
            }
        } else {
            showFeedback("Could not parse duration", color: .red)
        }
    }
    
    private func showFeedback(_ text: String, color: Color) {
        parseFeedback = text
        feedbackColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.parseFeedback == text {
                self?.parseFeedback = nil
            }
        }
    }
    
    private func formatFeedbackTime(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        var parts: [String] = []
        if hrs > 0 { parts.append("\(hrs)h") }
        if mins > 0 { parts.append("\(mins)m") }
        if secs > 0 || parts.isEmpty { parts.append("\(secs)s") }
        return parts.joined(separator: " ")
    }
    
    func parseDuration(_ input: String) -> (duration: TimeInterval, isAddition: Bool, isSubtraction: Bool)? {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanInput.isEmpty { return nil }
        
        var isAddition = false
        var isSubtraction = false
        var workingString = cleanInput
        
        if workingString.hasPrefix("add ") || workingString.hasPrefix("+") {
            isAddition = true
            workingString = workingString.replacingOccurrences(of: "add ", with: "")
            workingString = workingString.replacingOccurrences(of: "+", with: "")
        } else if workingString.hasPrefix("subtract ") || workingString.hasPrefix("sub ") || workingString.hasPrefix("-") {
            isSubtraction = true
            workingString = workingString.replacingOccurrences(of: "subtract ", with: "")
            workingString = workingString.replacingOccurrences(of: "sub ", with: "")
            workingString = workingString.replacingOccurrences(of: "-", with: "")
        }
        
        workingString = workingString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Colon Format (e.g. "1:22:10" -> 1h 22m 10s or "22:10" -> 22m 10s)
        let colonComponents = workingString.components(separatedBy: ":")
        if colonComponents.count > 1 {
            var hrs: Double = 0
            var mins: Double = 0
            var secs: Double = 0
            
            if colonComponents.count == 3 {
                hrs = Double(colonComponents[0]) ?? 0
                mins = Double(colonComponents[1]) ?? 0
                secs = Double(colonComponents[2]) ?? 0
            } else if colonComponents.count == 2 {
                mins = Double(colonComponents[0]) ?? 0
                secs = Double(colonComponents[1]) ?? 0
            }
            
            let total = (hrs * 3600) + (mins * 60) + secs
            return (total, isAddition, isSubtraction)
        }
        
        // 2. Keyword/Suffix Matching using standard scanning or basic regex helper
        var totalSecs: Double = 0
        var matched = false
        
        func extractValue(forPattern pattern: String) -> Double? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
            let range = NSRange(workingString.startIndex..<workingString.endIndex, in: workingString)
            if let match = regex.firstMatch(in: workingString, options: [], range: range) {
                if match.numberOfRanges > 1, let rangeInString = Range(match.range(at: 1), in: workingString) {
                    return Double(workingString[rangeInString])
                }
            }
            return nil
        }
        
        // Hours
        if let hVal = extractValue(forPattern: #"(\d+(?:\.\d+)?)\s*(?:h|hr|hours?)"#) {
            totalSecs += hVal * 3600
            matched = true
        }
        // Minutes
        if let mVal = extractValue(forPattern: #"(\d+(?:\.\d+)?)\s*(?:m|min|minutes?)"#) {
            totalSecs += mVal * 60
            matched = true
        }
        // Seconds
        if let sVal = extractValue(forPattern: #"(\d+(?:\.\d+)?)\s*(?:s|sec|seconds?)"#) {
            totalSecs += sVal
            matched = true
        }
        
        if matched {
            return (totalSecs, isAddition, isSubtraction)
        }
        
        // 3. Fallback: if just raw digits, interpret as minutes
        if let rawNum = Double(workingString) {
            return (rawNum * 60, isAddition, isSubtraction)
        }
        
        return nil
    }
    
    // MARK: - Data Management & Persistence
    
    func saveSession(title: String, notes: String, projectId: UUID?, taskGroupId: UUID? = nil, duration: TimeInterval) {
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Session" : title
        
        if let activeId = activeSessionId, let index = sessions.firstIndex(where: { $0.id == activeId }) {
            // Update the existing planned/running session to completed
            sessions[index].title = finalTitle
            sessions[index].notes = notes
            sessions[index].projectRef = projectId
            sessions[index].taskGroupRef = taskGroupId
            sessions[index].duration = duration
            sessions[index].date = Date()
            sessions[index].status = .completed
            
            // Move it to the front of the list so it appears as the most recent
            let completedSession = sessions.remove(at: index)
            sessions.insert(completedSession, at: 0)
        } else {
            // Create a brand new session (for stopwatch or ad-hoc timers)
            let newSession = Session(
                title: finalTitle,
                duration: duration,
                date: Date(),
                notes: notes,
                projectRef: projectId,
                status: .completed,
                taskGroupRef: taskGroupId
            )
            sessions.insert(newSession, at: 0)
        }
        saveData()
        
        // Reset Timer & Active Session
        activeSessionId = nil
        resetTimer()
        timerDuration = 0
        timeElapsed = 0
    }
    
    func planSession(title: String, duration: TimeInterval, projectId: UUID?, taskGroupId: UUID? = nil) {
        let plannedSession = Session(
            title: title.isEmpty ? "Planned Work Block" : title,
            duration: duration,
            date: Date(),
            notes: "",
            projectRef: projectId,
            status: .planned,
            taskGroupRef: taskGroupId,
            wasPlanned: true,
            datePlanned: Date()
        )
        sessions.insert(plannedSession, at: 0)
        saveData()
    }
    
    func createProject(name: String, colorHex: String) -> Project {
        let project = Project(name: name, colorHex: colorHex)
        projects.append(project)
        saveData()
        return project
    }
    
    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveData()
    }
    
    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        // Remove task groups belonging to this project
        taskGroups.removeAll { $0.projectRef == id }
        // Keep sessions but unset their projectRef and taskGroupRef
        for i in 0..<sessions.count {
            if sessions[i].projectRef == id {
                sessions[i].projectRef = nil
                sessions[i].taskGroupRef = nil
            }
        }
        saveData()
    }
    
    func createTaskGroup(name: String, projectRef: UUID) -> TaskGroup {
        let group = TaskGroup(name: name, projectRef: projectRef)
        taskGroups.append(group)
        saveData()
        return group
    }
    
    func deleteTaskGroup(id: UUID) {
        taskGroups.removeAll { $0.id == id }
        // Unset taskGroupRef for sessions in this group
        for i in 0..<sessions.count {
            if sessions[i].taskGroupRef == id {
                sessions[i].taskGroupRef = nil
            }
        }
        saveData()
    }
    
    private func loadData() {
        let defaults = UserDefaults.standard
        if let sessionsData = defaults.data(forKey: "SF_Sessions"),
           let decoded = try? JSONDecoder().decode([Session].self, from: sessionsData) {
            self.sessions = decoded
        }
        if let projectsData = defaults.data(forKey: "SF_Projects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: projectsData) {
            self.projects = decoded
        }
        if let groupsData = defaults.data(forKey: "SF_TaskGroups"),
           let decoded = try? JSONDecoder().decode([TaskGroup].self, from: groupsData) {
            self.taskGroups = decoded
        }
    }
    
    private func saveData() {
        let defaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(sessions) {
            defaults.set(encoded, forKey: "SF_Sessions")
        }
        if let encoded = try? JSONEncoder().encode(projects) {
            defaults.set(encoded, forKey: "SF_Projects")
        }
        if let encoded = try? JSONEncoder().encode(taskGroups) {
            defaults.set(encoded, forKey: "SF_TaskGroups")
        }
    }
}
