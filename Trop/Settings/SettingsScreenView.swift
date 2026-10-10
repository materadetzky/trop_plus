//
//  SettingsScreenView.swift
//  Trop
//
//  Created by Antigravity on 10/10/2026.
//

import SwiftUI

// Dedicated root view for the Settings tab with a native Liquid Glass aesthetic.
struct SettingsScreenView: View {
    @Environment(SettingsStore.self) private var settings
    @ObservedObject private var router = AppRouter.shared

    private let accentColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        @Bindable var settings = settings

        NavigationStack(path: $router.settingsPath) {
            ScrollView {
                VStack(spacing: 20) {
                    headerView

                    // 1. Theme & Accent Glass Card
                    glassCard(title: "Appearance", icon: "paintpalette.fill") {
                        VStack(spacing: 14) {
                            HStack {
                                Label("Theme Mode", systemImage: "circle.lefthalf.filled")
                                Spacer()
                                Picker("Theme Mode", selection: $settings.themeMode) {
                                    ForEach(ThemeMode.allCases) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 210)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Accent Color")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                LazyVGrid(columns: accentColumns, spacing: 12) {
                                    ForEach(AccentPreset.all) { preset in
                                        Button {
                                            applyAccentPreset(preset)
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(preset.color)
                                                    .frame(width: 34, height: 34)

                                                if settings.accentName == preset.name {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(preset.name)
                                    }
                                }
                            }

                            Divider()

                            HStack {
                                Label("Player Background", systemImage: "photo.fill")
                                Spacer()
                                Picker("Player Background", selection: $settings.playerBackgroundStyle) {
                                    ForEach(PlayerBackgroundStyle.allCases) { style in
                                        Text(style.displayName).tag(style)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Divider()

                            NavigationLink {
                                AppearanceSettingsView()
                            } label: {
                                HStack {
                                    Label("All Appearance Settings", systemImage: "paintpalette")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 2. Playback & Sound Glass Card
                    glassCard(title: "Playback & Audio", icon: "waveform.circle.fill") {
                        VStack(spacing: 14) {
                            NavigationLink {
                                EqualizerView()
                            } label: {
                                HStack {
                                    Label("Equalizer", systemImage: "slider.vertical.3")
                                    Spacer()
                                    Text(settings.equalizerEnabled ? "On" : "Off")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            HStack {
                                Label("Streaming Quality", systemImage: "antenna.radiowaves.left.and.right")
                                Spacer()
                                Picker("Streaming Quality", selection: $settings.audioQuality) {
                                    ForEach(AudioQuality.allCases) { q in
                                        Text(q.displayName).tag(q)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Divider()

                            Toggle(isOn: $settings.audioNormalization) {
                                Label("Audio Normalization", systemImage: "speaker.wave.2.fill")
                            }

                            Divider()

                            Toggle(isOn: $settings.gaplessPlayback) {
                                Label("Gapless Playback", systemImage: "arrow.right.arrow.left")
                            }

                            Divider()

                            Toggle(isOn: $settings.autoplaySimilar) {
                                Label("Autoplay Similar", systemImage: "infinity")
                            }

                            Divider()

                            Toggle(isOn: $settings.artworkSwipeNavigation) {
                                Label("Swipe Artwork to Skip", systemImage: "hand.draw.fill")
                            }

                            Divider()

                            NavigationLink {
                                PlayerSettingsView()
                            } label: {
                                HStack {
                                    Label("All Playback & Queue Settings", systemImage: "play.circle")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 3. Offline & Storage Glass Card
                    glassCard(title: "Offline & Downloads", icon: "arrow.down.circle.fill") {
                        VStack(spacing: 14) {
                            HStack {
                                Label("Download Quality", systemImage: "arrow.down.circle")
                                Spacer()
                                Picker("Download Quality", selection: $settings.downloadQuality) {
                                    ForEach(DownloadQuality.allCases) { dq in
                                        Text(dq.displayName).tag(dq)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Divider()

                            Toggle(isOn: $settings.wifiOnlyDownloads) {
                                Label("Download on Wi-Fi Only", systemImage: "wifi")
                            }

                            Divider()

                            Toggle(isOn: $settings.autoDownloadOnLike) {
                                Label("Auto-Download Liked Songs", systemImage: "heart.fill")
                            }

                            Divider()

                            NavigationLink {
                                DownloadSettingsView()
                            } label: {
                                HStack {
                                    Label("Storage Details & Offline Tracks", systemImage: "internaldrive")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 4. Content & Lyrics Glass Card
                    glassCard(title: "Content & Lyrics", icon: "text.quote") {
                        VStack(spacing: 14) {
                            NavigationLink {
                                LyricsSettingsView()
                            } label: {
                                HStack {
                                    Label("Lyrics Configuration", systemImage: "text.quote")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Toggle(isOn: $settings.hideExplicit) {
                                Label("Hide Explicit Content", systemImage: "exclamationmark.shield.fill")
                            }

                            Divider()

                            Toggle(isOn: $settings.trackPlayHistory) {
                                Label("Keep Play History", systemImage: "clock.fill")
                            }

                            Divider()

                            Toggle(isOn: $settings.trackSearchHistory) {
                                Label("Keep Search History", systemImage: "magnifyingglass")
                            }

                            Divider()

                            NavigationLink {
                                ContentSettingsView()
                            } label: {
                                HStack {
                                    Label("Content, Region & Library Sync", systemImage: "globe")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 5. Integrations & About
                    glassCard(title: "More Options", icon: "ellipsis.circle.fill") {
                        VStack(spacing: 14) {
                            NavigationLink {
                                IntegrationsSettingsView()
                            } label: {
                                HStack {
                                    Label("Discord & Last.fm", systemImage: "puzzlepiece.extension.fill")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            NavigationLink {
                                AboutSettingsView()
                            } label: {
                                HStack {
                                    Label("About Trop+", systemImage: "info.circle.fill")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .detailRouteDestinations()
            .miniPlayerTracksScroll()
        }
    }

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Customize your music experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundStyle(settings.accentColor)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func glassCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(settings.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.bottom, 2)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 20, intensity: 1.0)
    }

    private func applyAccentPreset(_ preset: AccentPreset) {
        settings.accentName = preset.name

        guard UIApplication.shared.supportsAlternateIcons else { return }
        let target = preset.alternateIconName
        guard UIApplication.shared.alternateIconName != target else { return }

        UIApplication.shared.setAlternateIconName(target) { error in
            if let error {
                Log.settings.error("Failed to set alternate icon '\(target ?? "nil")': \(error)")
            }
        }
    }
}
