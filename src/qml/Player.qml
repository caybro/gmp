pragma Singleton

import QtQuick 2.15
import QtMultimedia 5.15

Audio {
    id: root
    objectName: "AudioPlayer"

    readonly property alias currentPlayUrl: playlist.currentItemSource

    readonly property bool playing: playbackState === MediaPlayer.PlayingState
    readonly property bool canPlayPrevious: playlist.itemCount > 1 && playlist.currentIndex > 0
    readonly property bool canPlayNext: playlist.itemCount > 1 && playlist.currentIndex < playlist.itemCount - 1

    property alias currentPlaylistIndex: playlist.currentIndex

    audioRole: MediaPlayer.MusicRole
    autoPlay: true
    playlist: Playlist {
        id: playlist
        property int duration
        playbackMode: Playlist.Sequential
    }

    onError: {
        console.warn("!!! ERROR in audio playback:", errorString, "; code:", error);
    }
}
