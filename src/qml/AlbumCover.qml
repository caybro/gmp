import QtQuick 2.15

import org.gmp.model 1.0

Image {
    id: root
    width: 150
    height: 150
    asynchronous: true

    property string album

    property string refreshableSource: MusicIndexer.coverArtForAlbum(album)
    source: refreshableSource

    // FIXME proper force reloading
    function refresh() {
        source = "";
        source = Qt.binding(function() { return refreshableSource });
    }

    Connections {
        target: MusicIndexer
        ignoreUnknownSignals: true
        function onAlbumCoverArtChanged(album) {
            console.debug("!!! COVER")
            if (album === root.album) {
                root.sourceSize = undefined;
                root.refresh();
                root.sourceSize = Qt.size(150, 150);
                console.debug("!!! COVER RELOADED:", root.source)
            }
        }
    }
}
