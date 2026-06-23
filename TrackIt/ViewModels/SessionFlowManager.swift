//
//  SessionFlowManager.swift
//  TrackIt
//
//  Created by Antigravity on 6/3/26.
//

import SwiftUI
import Combine
import AppKit
import UserNotifications
import SwiftData


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
    var tags: [Tag] = []
    var groupTags: [Tag] = []
    
    // UI Navigation State
    var currentView: AppView = .timer
    var activeWorkspaceTab: WorkspaceTab = .dashboard
    var activeWorkspaceProjectId: UUID? = nil
    var showSaveSheet: Bool = false
    var timerTypeString: String = "Stopwatch" // "Countdown" or "Stopwatch"
    var activeSessionId: UUID? = nil
    var activeNotes: String = ""
    
    var showSettingsSheet: Bool = false
    var showTutorialSheet: Bool = false
    var completionSoundName: String = "Hero" {
        didSet {
            saveData()
        }
    }
    var appTheme: String = "System" {
        didSet {
            saveData()
        }
    }
    var keepTimerOnTop: Bool = false {
        didSet {
            saveData()
        }
    }
    var showInMenuBar: Bool = true {
        didSet {
            saveData()
            updateMenuBarVisibility()
        }
    }
    
    // Private Timer Helpers
    private var timer: Timer? = nil
    private var startDate: Date? = nil
    private var accumulatedTime: TimeInterval = 0
    private var statusItem: NSStatusItem? = nil
    
    var modelContainer: ModelContainer
    var modelContext: ModelContext
    
    init() {
        do {
            let schema = Schema([Project.self, Session.self, TaskGroup.self, Tag.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContainer = container
            self.modelContext = container.mainContext
            
            // Print the SwiftData SQLite database path so you can verify it on your Mac
            let url = modelConfiguration.url
            print("🗄️ SwiftData is storing your data here:")
            print(url.path)
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        loadData()
        

        // Request Notification Permissions and Set Delegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission request error: \(error)")
            }
        }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Setup Status Bar Item
        StatusItemTarget.shared.manager = self
        updateMenuBarVisibility()
    }
    
    // MARK: - Timer Controls
    
    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        updateStatusItem()
    }
    
    func pauseTimer() {
        guard isRunning else { return }
        isRunning = false
        if let start = startDate {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        timer?.invalidate()
        timer = nil
        updateStatusItem()
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
        activeNotes = ""
        updateStatusItem()
    }
    
    func startPlannedSession(_ session: Session) {
        resetTimer()
        timerDuration = session.duration
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
                triggerCompletionAlert()
            } else {
                timeElapsed = currentElapsed
            }
        } else {
            // Count-up Mode
            timeElapsed = currentElapsed
        }
        updateStatusItem()
    }
    
    private func triggerCompletionAlert() {
        // Play the native macOS sound
        NSSound(named: self.completionSoundName)?.play()
        
        // Determine the title of the finished block
        var sessionTitle = "Work Block"
        if let activeId = activeSessionId,
           let activeSession = sessions.first(where: { $0.id == activeId }) {
            sessionTitle = activeSession.title
        } else if !inputTimerText.isEmpty {
            sessionTitle = inputTimerText
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Completed"
        content.body = "\"\(sessionTitle)\" has finished!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func setupStatusItem() {
        DispatchQueue.main.async {
            self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = self.statusItem?.button {
                button.title = "00:00:00"
            }
            self.updateStatusItem()
        }
    }
    
    func updateMenuBarVisibility() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.showInMenuBar {
                if self.statusItem == nil {
                    self.setupStatusItem()
                } else {
                    self.updateStatusItem()
                }
            } else {
                if let item = self.statusItem {
                    NSStatusBar.system.removeStatusItem(item)
                    self.statusItem = nil
                }
            }
        }
    }
    
    func updateStatusItem() {
        guard let statusItem = statusItem, let button = statusItem.button else { return }
        let timeToDisplay = timeRemaining
        let formatted = formatTime(timeToDisplay)
        
        DispatchQueue.main.async {
            button.title = formatted
            
            // Rebuild the menu dynamically based on timer state
            let menu = NSMenu()
            
            let showItem = NSMenuItem(title: "Show App", action: #selector(StatusItemTarget.showAppWindow), keyEquivalent: "")
            showItem.target = StatusItemTarget.shared
            menu.addItem(showItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Start/Pause Item
            let startPauseTitle = self.isRunning ? "Pause" : "Start"
            let startPauseItem = NSMenuItem(title: startPauseTitle, action: #selector(StatusItemTarget.toggleTimer), keyEquivalent: "")
            startPauseItem.target = StatusItemTarget.shared
            menu.addItem(startPauseItem)
            
            // Reset Item
            let resetItem = NSMenuItem(title: "Reset", action: #selector(StatusItemTarget.resetTimer), keyEquivalent: "")
            resetItem.target = StatusItemTarget.shared
            menu.addItem(resetItem)
            
            // Reset and Pause Item
            let resetPauseItem = NSMenuItem(title: "Reset and Pause", action: #selector(StatusItemTarget.resetAndPauseTimer), keyEquivalent: "")
            resetPauseItem.target = StatusItemTarget.shared
            menu.addItem(resetPauseItem)
            
            menu.addItem(NSMenuItem.separator())
            let settingsItem = NSMenuItem(title: "Settings", action: #selector(StatusItemTarget.openSettings), keyEquivalent: ",")
            settingsItem.target = StatusItemTarget.shared
            menu.addItem(settingsItem)
            
            let tutorialItem = NSMenuItem(title: "Tutorial", action: #selector(StatusItemTarget.openTutorial), keyEquivalent: "?")
            tutorialItem.target = StatusItemTarget.shared
            if let icon = NSImage(systemSymbolName: "book", accessibilityDescription: nil) {
                tutorialItem.image = icon
            }
            menu.addItem(tutorialItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q")
            menu.addItem(quitItem)
            
            statusItem.menu = menu
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hrs = Int(time) / 3600
        let mins = (Int(time) % 3600) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
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
                let targetDuration = parsedSecs
                resetTimer()
                timerDuration = targetDuration
                startTimer()
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
        if let hVal = extractValue(forPattern: #"(\d+(?:\.\d+)?)\s*(?:h|hrs?|hours?)"#) {
            totalSecs += hVal * 3600
            matched = true
        }
        // Minutes
        if let mVal = extractValue(forPattern: #"(\d+(?:\.\d+)?)\s*(?:m|mins?|minutes?)"#) {
            totalSecs += mVal * 60
            matched = true
        }
        // Seconds
        if let sVal = extractValue(forPattern: #"(\d+(?:\.\d+)?)\s*(?:s|secs?|seconds?)"#) {
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
    
    func saveSession(title: String, notes: String, projectId: UUID?, taskGroupId: UUID? = nil, tagIds: [UUID] = [], duration: TimeInterval) {
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Session" : title
        
        if let activeId = activeSessionId, let index = sessions.firstIndex(where: { $0.id == activeId }) {
            // Update the existing planned/running session to completed
            sessions[index].title = finalTitle
            sessions[index].notes = notes
            sessions[index].projectRef = projectId
            sessions[index].taskGroupRef = taskGroupId
            sessions[index].tagRefs = tagIds
            sessions[index].duration = duration
            sessions[index].date = Date()
            sessions[index].status = .completed
            
            let completedSession = sessions.remove(at: index)
            sessions.insert(completedSession, at: 0)
        } else {
            // Create a brand new session
            let newSession = Session(
                title: finalTitle,
                duration: duration,
                date: Date(),
                notes: notes,
                projectRef: projectId,
                status: .completed,
                taskGroupRef: taskGroupId,
                tagRefs: tagIds
            )
            sessions.insert(newSession, at: 0)
            modelContext.insert(newSession)
        }
        saveData()
        
        activeSessionId = nil
        resetTimer()
        timerDuration = 0
        timeElapsed = 0
    }
    
    func planSession(title: String, duration: TimeInterval, projectId: UUID?, taskGroupId: UUID? = nil, tagIds: [UUID] = []) {
        let plannedSession = Session(
            title: title.isEmpty ? "Planned Work Block" : title,
            duration: duration,
            date: Date(),
            notes: "",
            projectRef: projectId,
            status: .planned,
            taskGroupRef: taskGroupId,
            tagRefs: tagIds,
            wasPlanned: true,
            datePlanned: Date()
        )
        sessions.insert(plannedSession, at: 0)
        modelContext.insert(plannedSession)
        saveData()
    }
    
    func createProject(name: String, colorHex: String) -> Project {
        let project = Project(name: name, colorHex: colorHex)
        projects.append(project)
        modelContext.insert(project)
        saveData()
        return project
    }
    
    func deleteSession(id: UUID) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            let session = sessions.remove(at: index)
            modelContext.delete(session)
            saveData()
        }
    }
    
    func deleteProject(id: UUID) {
        if let index = projects.firstIndex(where: { $0.id == id }) {
            let proj = projects.remove(at: index)
            modelContext.delete(proj)
        }
        // Remove task groups belonging to this project
        let groupsToDelete = taskGroups.filter { $0.projectRef == id }
        for group in groupsToDelete {
            modelContext.delete(group)
        }
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
    
    func createTaskGroup(name: String, projectRef: UUID, tagRefs: [UUID] = []) -> TaskGroup {
        let group = TaskGroup(name: name, projectRef: projectRef, tagRefs: tagRefs)
        taskGroups.append(group)
        modelContext.insert(group)
        saveData()
        return group
    }
    
    func updateTaskGroup(id: UUID, name: String, tagRefs: [UUID]) {
        if let index = taskGroups.firstIndex(where: { $0.id == id }) {
            taskGroups[index].name = name
            taskGroups[index].tagRefs = tagRefs
            saveData()
        }
    }
    
    func deleteTaskGroup(id: UUID) {
        if let index = taskGroups.firstIndex(where: { $0.id == id }) {
            let group = taskGroups.remove(at: index)
            modelContext.delete(group)
        }
        // Unset taskGroupRef for sessions in this group
        for i in 0..<sessions.count {
            if sessions[i].taskGroupRef == id {
                sessions[i].taskGroupRef = nil
            }
        }
        saveData()
    }
    
    func moveSession(id: UUID, toGroupId: UUID?) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].taskGroupRef = toGroupId
            saveData()
        }
    }
    
    func updateSessionTags(id: UUID, tagIds: [UUID]) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].tagRefs = tagIds
            saveData()
        }
    }
    
    func updateSessionNotes(id: UUID, notes: String) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].notes = notes
            saveData()
        }
    }
    
    func createTag(name: String, colorHex: String) -> Tag {
        let tag = Tag(name: name, colorHex: colorHex)
        tags.append(tag)
        modelContext.insert(tag)
        saveData()
        return tag
    }
    
    func deleteTag(id: UUID) {
        if let index = tags.firstIndex(where: { $0.id == id }) {
            let tag = tags.remove(at: index)
            modelContext.delete(tag)
        }
        for i in 0..<sessions.count {
            sessions[i].tagRefs = sessions[i].tagRefs?.filter { $0 != id }
        }
        saveData()
    }
    
    func createGroupTag(name: String, colorHex: String) -> Tag {
        let tag = Tag(name: name, colorHex: colorHex, isGroupTag: true)
        groupTags.append(tag)
        modelContext.insert(tag)
        saveData()
        return tag
    }
    
    func deleteGroupTag(id: UUID) {
        if let index = groupTags.firstIndex(where: { $0.id == id }) {
            let tag = groupTags.remove(at: index)
            modelContext.delete(tag)
        }
        for i in 0..<taskGroups.count {
            taskGroups[i].tagRefs = taskGroups[i].tagRefs?.filter { $0 != id }
        }
        saveData()
    }
    
    func updateGroupTags(id: UUID, tagIds: [UUID]) {
        if let index = taskGroups.firstIndex(where: { $0.id == id }) {
            taskGroups[index].tagRefs = tagIds
            saveData()
        }
    }


    
    private func loadData() {
        let defaults = UserDefaults.standard
        self.completionSoundName = defaults.string(forKey: "SF_CompletionSoundName") ?? "Hero"
        self.appTheme = defaults.string(forKey: "SF_AppTheme") ?? "System"
        self.keepTimerOnTop = defaults.bool(forKey: "SF_KeepTimerOnTop")
        if defaults.object(forKey: "SF_ShowInMenuBar") != nil {
            self.showInMenuBar = defaults.bool(forKey: "SF_ShowInMenuBar")
        } else {
            self.showInMenuBar = true
        }

        // Fetch from SwiftData
        do {
            let pDesc = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)])
            self.projects = try modelContext.fetch(pDesc)
            
            let sDesc = FetchDescriptor<Session>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            self.sessions = try modelContext.fetch(sDesc)
            
            let tgDesc = FetchDescriptor<TaskGroup>(sortBy: [SortDescriptor(\.createdAt)])
            self.taskGroups = try modelContext.fetch(tgDesc)
            
            let tDesc = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.createdAt)])
            let allTags = try modelContext.fetch(tDesc)
            self.tags = allTags.filter { !$0.isGroupTag }
            self.groupTags = allTags.filter { $0.isGroupTag }
        } catch {
            print("Failed to fetch SwiftData: \(error)")
        }

        // Migration from UserDefaults
        if self.sessions.isEmpty && self.projects.isEmpty && self.tags.isEmpty && self.taskGroups.isEmpty {
            var migrated = false
            if let projectsData = defaults.data(forKey: "SF_Projects"),
               let decoded = try? JSONDecoder().decode([LegacyProject].self, from: projectsData) {
                for dp in decoded {
                    let p = Project(id: dp.id, name: dp.name, colorHex: dp.colorHex, createdAt: dp.createdAt)
                    self.projects.append(p)
                    modelContext.insert(p)
                }
                migrated = true
            }
            if let sessionsData = defaults.data(forKey: "SF_Sessions"),
               let decoded = try? JSONDecoder().decode([LegacySession].self, from: sessionsData) {
                for ds in decoded {
                    let s = Session(id: ds.id, title: ds.title, duration: ds.duration, date: ds.date, notes: ds.notes, projectRef: ds.projectRef, status: ds.status, voiceNoteUrl: ds.voiceNoteUrl, taskGroupRef: ds.taskGroupRef, tagRefs: ds.tagRefs, wasPlanned: ds.wasPlanned, datePlanned: ds.datePlanned)
                    self.sessions.append(s)
                    modelContext.insert(s)
                }
                migrated = true
            }
            if let groupsData = defaults.data(forKey: "SF_TaskGroups"),
               let decoded = try? JSONDecoder().decode([LegacyTaskGroup].self, from: groupsData) {
                for dt in decoded {
                    let tg = TaskGroup(id: dt.id, name: dt.name, projectRef: dt.projectRef, createdAt: dt.createdAt, tagRefs: dt.tagRefs)
                    self.taskGroups.append(tg)
                    modelContext.insert(tg)
                }
                migrated = true
            }
            if let tagsData = defaults.data(forKey: "SF_Tags"),
               let decoded = try? JSONDecoder().decode([LegacyTag].self, from: tagsData) {
                for dt in decoded {
                    let tag = Tag(id: dt.id, name: dt.name, colorHex: dt.colorHex, createdAt: dt.createdAt, isGroupTag: false)
                    self.tags.append(tag)
                    modelContext.insert(tag)
                }
                migrated = true
            }
            if let groupTagsData = defaults.data(forKey: "SF_GroupTags"),
               let decoded = try? JSONDecoder().decode([LegacyTag].self, from: groupTagsData) {
                for dt in decoded {
                    let tag = Tag(id: dt.id, name: dt.name, colorHex: dt.colorHex, createdAt: dt.createdAt, isGroupTag: true)
                    self.groupTags.append(tag)
                    modelContext.insert(tag)
                }
                migrated = true
            }
            if migrated {
                try? modelContext.save()
                defaults.removeObject(forKey: "SF_Projects")
                defaults.removeObject(forKey: "SF_Sessions")
                defaults.removeObject(forKey: "SF_TaskGroups")
                defaults.removeObject(forKey: "SF_Tags")
                defaults.removeObject(forKey: "SF_GroupTags")
            }
        }
    }
    
    private func saveData() {
        let defaults = UserDefaults.standard
        defaults.set(completionSoundName, forKey: "SF_CompletionSoundName")
        defaults.set(appTheme, forKey: "SF_AppTheme")
        defaults.set(keepTimerOnTop, forKey: "SF_KeepTimerOnTop")
        defaults.set(showInMenuBar, forKey: "SF_ShowInMenuBar")
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save SwiftData: \(error)")
        }
    }
}
