//
//  FullPlayerView.swift
//  Trop
//
//  Created by 686udjie on 18/07/2026.
//

import SwiftUI

struct FullPlayerView: View {
    let onCollapse: () -> Void

    @Environment(SettingsStore.self) private var settings
    private let player = PlayerController.shared
    @Bindable private var np = NowPlaying.shared
    @State private var editingProgress: Float = 0
    @State private var isEditingSlider = false
    @State private var collapseOffset: CGFloat = 0

    @ObservedObject private var likeStore = LikeStore.shared
    private var isLiked: Bool {
        guard let song = np.queueSongs.indices.contains(np.queueIndex) ? np.queueSongs[np.queueIndex] : nil else { return false }
        return likeStore.isLiked(videoId: song.videoId)
    }
    @State private var showLyrics = false
    @State private var showQueue = false
    @State private var pendingRoute: DetailRoute?
    @State private var showSongMenu = false
    @State private var artworkEntryOffset: CGFloat = 0
    @State private var currentLyrics: [LyricLine] = []

    private let horizontalGridPadding: CGFloat = 28

    private var activeLyricText: String? {
        let synchronizedLines = currentLyrics.filter {
            $0.startTime != nil &&
                !$0.text.trimmingCharacters(in: CharacterSet(charactersIn: "♪*· ")).isEmpty
        }
        guard let firstLine = synchronizedLines.first else { return nil }

        let lyricTime = np.currentTime + settings.lyricsOffsetSeconds
        return synchronizedLines.last { line in
            guard let startTime = line.startTime else { return false }
            return startTime <= lyricTime
        }?.text ?? firstLine.text
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Layer (Fluid animated colors + Liquid Glass frosted refraction)
                playerBackground

                // Main Foreground Content
                VStack(spacing: 0) {
                    // Top Drag Indicator
                    topDragBar

                    if showLyrics {
                        LyricsView(
                            showLyrics: $showLyrics,
                            pendingRoute: $pendingRoute,
                            progressSlider: { progressSlider }
                        )
                    } else if np.isVideoMode && np.hasVideo {
                        musicVideoContent
                    } else if showQueue {
                        QueueView(
                            showQueue: $showQueue,
                            isShuffleOn: $np.isShuffleOn,
                            isRepeatOn: $np.isRepeatOn,
                            editingProgress: $editingProgress,
                            isEditingSlider: $isEditingSlider,
                            pendingRoute: $pendingRoute,
                            progressSlider: { progressSlider }
                        )
                    } else {
                        mainPlayerContent(geometry: geometry)
                    }
                }
            }
            .offset(y: collapseOffset)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: collapseOffset)
            .animation(.easeInOut(duration: 0.35), value: showQueue)
            .simultaneousGesture(collapseDrag)
            .onChange(of: np.videoId) { _, _ in
                np.isVideoMode = false
                showLyrics = false
                showQueue = false
                preloadLyrics()
            }
            .onChange(of: np.queueSongs.count) { _, _ in
                np.preloadNeighborArtwork()
                preloadLyrics()
            }
            .onChange(of: np.queueIndex) { _, _ in
                np.preloadNeighborArtwork()
            }
            .onChange(of: showQueue) { _, newValue in
                if newValue { np.preloadNeighborArtwork() }
            }
            .task { np.preloadNeighborArtwork() }
            .task(id: np.videoId) { await loadCurrentLyrics() }
            .sheet(isPresented: $showSongMenu) {
                if let song = np.queueSongs.indices.contains(np.queueIndex) ? np.queueSongs[np.queueIndex] : nil {
                    PlayerMenuSheet(song: song, onCollapseRequest: { onCollapse() })
                }
            }
            .background(
                Color.clear
                    .detailRouteSheet(item: $pendingRoute)
            )
        }
    }

    // MARK: - Background
    @ViewBuilder
    private var playerBackground: some View {
        if np.isVideoMode && np.hasVideo {
            Color.black.ignoresSafeArea()
        } else if settings.playerBackgroundStyle == .solid {
            ZStack {
                Color.black
                Rectangle().fill(.ultraThinMaterial)
            }
            .ignoresSafeArea()
        } else {
            ZStack {
                // Dynamic dominant color backdrop
                LinearGradient(
                    colors: [
                        np.dominantColors.first ?? Color(red: 0.15, green: 0.15, blue: 0.22),
                        np.dominantColors.last ?? Color(red: 0.06, green: 0.06, blue: 0.10)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(np.dominantColors.first ?? .blue)
                    .frame(width: 440, height: 440)
                    .blur(radius: 120)
                    .opacity(0.50)
                    .offset(y: -140)

                Circle()
                    .fill(np.dominantColors.last ?? .purple)
                    .frame(width: 400, height: 400)
                    .blur(radius: 110)
                    .opacity(0.40)
                    .offset(x: 100, y: 150)

                // Frosted glass refraction
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Native Liquid Glass iridescent caustics & specular gloss sheen
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.16), location: 0),
                        .init(color: Color(red: 0.65, green: 0.85, blue: 1.0).opacity(0.08), location: 0.28),
                        .init(color: Color(red: 1.0, green: 0.70, blue: 0.90).opacity(0.06), location: 0.55),
                        .init(color: .clear, location: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: np.dominantColors)
        }
    }

    // MARK: - Top Drag Indicator
    private var topDragBar: some View {
        Capsule()
            .fill(.white.opacity(0.38))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .contentShape(Rectangle().size(width: 80, height: 32))
            .onTapGesture {
                if showLyrics {
                    withAnimation(.easeInOut(duration: 0.3)) { showLyrics = false }
                }
            }
            .accessibilityLabel(showLyrics ? "Close lyrics" : "Collapse player")
    }

    // MARK: - Main Player Content
    @ViewBuilder
    private func mainPlayerContent(geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        // Artwork size dynamically calculated so everything fits gracefully on any iPhone
        let artworkSide = min(screenWidth - (horizontalGridPadding * 2), screenHeight * 0.38)

        VStack(spacing: 0) {
            Spacer(minLength: 6).frame(maxHeight: 14)

            // 1. Artwork Floating Card
            artworkContainer(size: artworkSide)

            Spacer(minLength: 16)

            // 2. Track Title, Artist, Like & Options
            titleAndActionsRow
                .padding(.horizontal, horizontalGridPadding)
                .padding(.bottom, 12)

            // 3. Lyrics Pill (if available)
            lyricsPreviewPill
                .padding(.horizontal, horizontalGridPadding)
                .padding(.bottom, 14)

            // 4. Progress Scrubber
            progressSlider
                .padding(.horizontal, horizontalGridPadding)
                .padding(.bottom, 18)

            // 5. Playback Transport Controls
            PlaybackControlsRow(
                isPlaying: np.isPlaying,
                hasPrevious: np.hasPrevious,
                hasNext: np.hasNext,
                onPrevious: { np.playPrevious() },
                onPlayPause: { player.togglePlayPause() },
                onNext: { np.playNext() }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: np.isPlaying)
            .padding(.horizontal, horizontalGridPadding)
            .padding(.bottom, 22)

            // 6. Secondary Actions (AirPlay & Queue)
            SecondaryActionsRow(
                showQueue: $showQueue,
                isRepeatOn: $np.isRepeatOn
            )
            .padding(.horizontal, horizontalGridPadding)

            Spacer(minLength: 10).frame(maxHeight: 28)
        }
    }

    // MARK: - Artwork Card
    private func artworkContainer(size: CGFloat) -> some View {
        artwork
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.35), location: 0),
                                .init(color: .white.opacity(0.08), location: 0.5),
                                .init(color: .white.opacity(0.18), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
            .scaleEffect(np.isPlaying ? 1.0 : 0.88)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: np.isPlaying)
            .offset(x: artworkEntryOffset)
            .gesture(artworkSwipe)
    }

    // MARK: - Lyrics Preview Pill
    @ViewBuilder
    private var lyricsPreviewPill: some View {
        if let activeLyricText {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLyrics = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.90))

                    Text(activeLyricText)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .liquidGlassCapsule(intensity: 1.15)
                .foregroundStyle(.white)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Current lyric: \(activeLyricText). Open lyrics")
        } else {
            Color.clear.frame(height: 10)
        }
    }

    // MARK: - Title and Actions Row
    private var titleAndActionsRow: some View {
        HStack(alignment: .center, spacing: 14) {
            PlayerTitleBlock(
                title: np.title,
                artist: np.displayArtist,
                spacing: 3,
                titleFont: .title2.weight(.bold),
                titleHeight: 28
            )

            HStack(spacing: 12) {
                PlayerLikeButton(isLiked: isLiked) {
                    guard let song = np.queueSongs.indices.contains(np.queueIndex) ? np.queueSongs[np.queueIndex] : nil else { return }
                    Task { await likeStore.toggle(song: song) }
                }

                if np.queueSongs.indices.contains(np.queueIndex) {
                    PlayerOptionsButton {
                        showSongMenu = true
                    }
                }
            }
        }
    }

    // MARK: - Progress Scrubber
    private var progressSlider: some View {
        VStack(spacing: 6) {
            ProgressBar(
                progress: Binding(
                    get: { isEditingSlider ? editingProgress : np.progress },
                    set: { editingProgress = $0 }
                ),
                accentColor: np.dominantColors.first ?? .white,
                isPlaying: np.isPlaying,
                onEditingChanged: { editing in
                    if editing {
                        editingProgress = np.progress
                    } else {
                        let target = TimeInterval(editingProgress) * np.duration
                        player.seek(to: target)
                        np.currentTime = target
                        player.updateNowPlayingProgress()
                    }
                    isEditingSlider = editing
                }
            )

            HStack {
                Text(DurationFormat.playbackTime(isEditingSlider
                    ? TimeInterval(editingProgress) * np.duration
                    : np.currentTime))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                Text(DurationFormat.playbackTime(np.duration))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    // MARK: - Gestures

    /// Swipe left/right on the artwork to skip tracks (toggleable in Settings).
    private var artworkSwipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard settings.artworkSwipeNavigation else { return }
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if value.translation.width < -60, np.hasNext {
                    np.playNext()
                    slideInArtwork(fromLeft: false)
                } else if value.translation.width > 60, np.hasPrevious {
                    np.playPrevious()
                    slideInArtwork(fromLeft: true)
                }
            }
    }

    private func slideInArtwork(fromLeft: Bool) {
        artworkEntryOffset = fromLeft ? -600 : 600
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            artworkEntryOffset = 0
        }
    }

    /// Swipe down anywhere to collapse.
    private var collapseDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard value.translation.height > 0,
                      value.translation.height > abs(value.translation.width) else { return }
                collapseOffset = value.translation.height
            }
            .onEnded { value in
                defer { collapseOffset = 0 }
                let isVertical = value.translation.height > abs(value.translation.width)
                if isVertical, value.translation.height > 140 {
                    onCollapse()
                }
            }
    }

    // MARK: - Player Content & Preload

    private func preloadLyrics() {
        guard let id = np.videoId else { return }
        let upcoming = np.upcomingSongs(prefixLimit: 3).map(\.videoId)
        Task { await LyricsService.shared.preload(videoId: id, upcoming: upcoming) }
    }

    private func loadCurrentLyrics() async {
        guard let videoId = np.videoId else {
            currentLyrics = []
            return
        }
        currentLyrics = []
        guard let lines = try? await LyricsService.shared.fetchLyrics(videoId: videoId),
              !Task.isCancelled,
              np.videoId == videoId else { return }
        currentLyrics = lines
    }

    private var musicVideoContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        np.isVideoMode = false
                        showQueue = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.48), in: Circle())
                }
                .accessibilityLabel("Return to artwork player")

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            musicVideoStage

            QueueView(
                showQueue: $showQueue,
                isShuffleOn: $np.isShuffleOn,
                isRepeatOn: $np.isRepeatOn,
                editingProgress: $editingProgress,
                isEditingSlider: $isEditingSlider,
                pendingRoute: $pendingRoute,
                progressSlider: { progressSlider },
                isVideoMode: true
            )
            .frame(maxHeight: .infinity)
        }
    }

    private var musicVideoStage: some View {
        artwork
            .aspectRatio(16 / 9, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    @ViewBuilder
    private var artwork: some View {
        Group {
            if np.isVideoMode, np.hasVideo {
                ZStack {
                    VideoPlayerView()
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white, location: 0.12),
                                    .init(color: .white, location: 0.95),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    if !np.isVideoReady {
                        artworkImage
                            .transition(.opacity)
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .animation(.easeOut(duration: 0.2), value: np.isVideoReady)
            } else {
                artworkImage
                .onTapGesture {
                    guard np.hasVideo else { return }
                    showQueue = true
                    player.setVideoMode()
                }
            }
        }
    }

    /// Song artwork (or placeholder), filling its container.
    private var artworkImage: some View {
        ZStack {
            if let uiImage = np.thumbnailUIImage {
                let cropped = uiImage.centerCroppedSquare()
                GeometryReader { geo in
                    Image(uiImage: cropped)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            } else {
                ZStack {
                    Color.white.opacity(0.1)
                    Image(systemName: "music.note")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
    }
}
