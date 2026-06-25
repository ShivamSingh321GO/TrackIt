import SwiftUI

struct SettingsSheet: View {
    @Bindable var manager: SessionFlowManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var isDark: Bool {
        if manager.appTheme == "Dark" {
            return true
        } else if manager.appTheme == "Light" {
            return false
        } else {
            return colorScheme == .dark
        }
    }
    
    let soundOptions = ["Funk", "Hero", "Glass", "Submarine", "Morse", "Sosumi", "Tink", "Ping", "Blow", "Purr"]
    let themeOptions = ["Light", "Dark", "Glass"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text("Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 14) {
                // Sound Picker
                HStack(spacing: 12) {
                    Text("Alert sound:")
                        .font(.body)
                        .frame(width: 110, alignment: .trailing)
                    
                    Picker("", selection: $manager.completionSoundName) {
                        ForEach(soundOptions, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 140)
                    
                    Button(action: {
                        NSSound(named: manager.completionSoundName)?.play()
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                
                // Theme Picker
                HStack(spacing: 12) {
                    Text("Theme:")
                        .font(.body)
                        .frame(width: 110, alignment: .trailing)
                    
                    Picker("", selection: $manager.appTheme) {
                        ForEach(themeOptions, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                
                // Checkboxes
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Keep timer on top", isOn: $manager.keepTimerOnTop)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Show in menu bar", isOn: $manager.showInMenuBar)
                        .toggleStyle(.checkbox)
                }
                .padding(.leading, 122)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                    SettingsWindowManager.shared.closeSettings()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .padding(.top, manager.appTheme == "Glass" ? 15 : 0)
        .frame(width: 480)
        .frame(maxHeight: .infinity)
        .background {
            if manager.appTheme == "Glass" {
                ZStack {
                    VisualEffectView(
                        material: isDark ? .hudWindow : .sidebar,
                        blendingMode: .behindWindow
                    )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.03 : 0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.15 : 0.4),
                                    Color.white.opacity(isDark ? 0.05 : 0.1),
                                    Color.black.opacity(isDark ? 0.15 : 0.05),
                                    Color.white.opacity(isDark ? 0.1 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(manager.appTheme == "Dark" ? .dark : (manager.appTheme == "Light" ? .light : nil))
        .onChange(of: manager.completionSoundName) { oldValue, newValue in
            NSSound(named: newValue)?.play()
        }
    }
}
