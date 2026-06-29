import SwiftUI

struct SettingsSheet: View {
    @Bindable var manager: SessionFlowManager
    @Environment(\.dismiss) var dismiss
    
    let soundOptions = ["Funk", "Hero", "Glass", "Submarine", "Morse", "Sosumi", "Tink", "Ping", "Blow", "Purr"]
    let themeOptions = ["Dark", "Light"]
    
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
        .frame(width: 480, height: 260)
        .onChange(of: manager.completionSoundName) { oldValue, newValue in
            NSSound(named: newValue)?.play()
        }
    }
}
