import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @Environment(\.dismiss)     private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme

    private var effectiveScheme: ColorScheme {
        AppTheme.resolveColorScheme(
            appScheme:    settingsManager.settings.colorScheme,
            systemScheme: systemColorScheme
        )
    }

    private var lang: AppLanguage { settingsManager.resolvedLanguage }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(for: effectiveScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        appearanceSection
                        languageSection
                        teleprompterSection
                        informationSection
                        resetButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle(L10n.settings.localized(for: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done.localized(for: lang)) { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }
        }
        .preferredColorScheme(settingsManager.settings.colorScheme.colorScheme)
        .id(settingsManager.settings.colorScheme)
    }

    // MARK: - Sekcja wyglądu

    private var appearanceSection: some View {
        settingsSection(title: L10n.appearance.localized(for: lang), icon: "paintbrush") {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.colorTheme.localized(for: lang))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))

                HStack(spacing: 12) {
                    ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                        ColorSchemeButton(
                            scheme: scheme,
                            isSelected: settingsManager.settings.colorScheme == scheme
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settingsManager.settings.colorScheme = scheme
                            }
                        }
                    }
                }

                Text(colorSchemeDescription)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Sekcja języka

    private var languageSection: some View {
        settingsSection(title: L10n.language.localized(for: lang), icon: "globe") {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.languageDesc.localized(for: lang))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))

                VStack(spacing: 0) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { index, language in
                        LanguageRow(
                            language: language,
                            isSelected: settingsManager.settings.language == language,
                            effectiveScheme: effectiveScheme
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settingsManager.settings.language = language
                            }
                        }

                        if index < AppLanguage.allCases.count - 1 {
                            Divider()
                                .background(AppTheme.separator(for: effectiveScheme))
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.background(for: effectiveScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.separator(for: effectiveScheme), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Sekcja telepromptera

    private var teleprompterSection: some View {
        settingsSection(title: L10n.teleprompterSettings.localized(for: lang), icon: "play.rectangle") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.onManualScroll.localized(for: lang))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))

                    Picker("", selection: $settingsManager.settings.stopScrollOnManualScroll) {
                        Text(L10n.stopAutoScroll.localized(for: lang)).tag(true)
                        Text(L10n.continueAutoScroll.localized(for: lang)).tag(false)
                    }
                    .pickerStyle(.segmented)

                    Text(settingsManager.settings.stopScrollOnManualScroll
                         ? L10n.stopAutoScrollDesc.localized(for: lang)
                         : L10n.continueAutoScrollDesc.localized(for: lang))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
                }

                Divider().background(AppTheme.separator(for: effectiveScheme))

                Toggle(isOn: $settingsManager.settings.keepScreenAwake) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.keepScreenOn.localized(for: lang))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))
                        Text(L10n.keepScreenOnDesc.localized(for: lang))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
                    }
                }
                .tint(.orange)
            }
        }
    }

    // MARK: - Sekcja informacji

    private var informationSection: some View {
        settingsSection(title: L10n.information.localized(for: lang), icon: "info.circle") {
            VStack(spacing: 12) {
                HStack {
                    Text(L10n.appVersion.localized(for: lang))
                        .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
                }
                .font(.subheadline)

                Divider().background(AppTheme.separator(for: effectiveScheme))

                HStack {
                    Text(L10n.chordsInDatabase.localized(for: lang))
                        .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))
                    Spacer()
                    Text("50+")
                        .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Przycisk reset

    private var resetButton: some View {
        Button {
            settingsManager.reset()
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text(L10n.resetSettings.localized(for: lang))
            }
            .font(.subheadline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }

    // MARK: - Helpers

    private var colorSchemeDescription: String {
        switch settingsManager.settings.colorScheme {
        case .system: return L10n.themeSystemDesc.localized(for: lang)
        case .light:  return L10n.themeLightDesc.localized(for: lang)
        case .dark:   return L10n.themeDarkDesc.localized(for: lang)
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground(for: effectiveScheme))
            )
        }
    }
}

// MARK: - Wiersz wyboru języka

private struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let effectiveScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.title2)
                    .frame(width: 32)

                Text(language.displayName)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Przycisk wyboru motywu

struct ColorSchemeButton: View {
    let scheme: AppColorScheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Group {
                        switch scheme {
                        case .light:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.92))
                        case .dark:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.12))
                        case .system:
                            HStack(spacing: 0) {
                                Color(white: 0.92)
                                Color(white: 0.12)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(width: 64, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.orange : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )

                    Image(systemName: scheme.icon)
                        .font(.title3)
                        .foregroundStyle(scheme == .dark ? .yellow : .orange)
                }

                Text(scheme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .orange : .gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
