#include "trackmodel.h"

#include <QDirIterator>
#include <QFile>
#include <QDebug>
#include <QStandardPaths>
#include <QUrl>

#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/mpegfile.h>

namespace {
bool localeAwareCompare(const QString &s1, const QString &s2) {
    return s1.localeAwareCompare(s2) < 0;
}
}

TrackModel::TrackModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_roleNames = {
        {RoleTrackUrl, QByteArrayLiteral("url")},
        {RoleTrackFilepath, QByteArrayLiteral("filePath")},
        {RoleTrackTitle, QByteArrayLiteral("title")},
        {RoleTrackArtist, QByteArrayLiteral("artist")},
        {RoleTrackAlbum, QByteArrayLiteral("album")},
        {RoleTrackYear, QByteArrayLiteral("year")},
        {RoleTrackGenre, QByteArrayLiteral("genre")},
        {RoleTrackNumber, QByteArrayLiteral("trackNo")},
        {RoleTrackLength, QByteArrayLiteral("length")}
    };
    scanAll();
}

TrackModel::~TrackModel() = default;

QStringList TrackModel::artists() const
{
    return m_artists;
}

QStringList TrackModel::albums() const
{
    return m_albums;
}

QStringList TrackModel::genres() const
{
    return m_genres;
}

void TrackModel::scanAll()
{
    beginResetModel();
    const auto musicPaths = QStandardPaths::standardLocations(QStandardPaths::MusicLocation);
    TagLib::FileRef f;
    QSet<QString> artists, albums, genres;
    for (const auto &rootPath: musicPaths) { // TODO watch paths for changes
        QDirIterator it(rootPath, {QStringLiteral("*.mp3"), QStringLiteral("*.ogg"), QStringLiteral("*.oga"),
                                   QStringLiteral("*.wma"), QStringLiteral("*.wav"), QStringLiteral("*.flac"),
                                   QStringLiteral("*.m4a"), QStringLiteral("*.aac")}, // FIXME find out dynamically
                        QDir::Files|QDir::NoDotAndDotDot|QDir::Readable,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QString filePath = it.filePath();
            //qDebug() << "Found audio file:" << filePath;
            f = TagLib::FileRef(QFile::encodeName(filePath));

            uint pos = 0;
            TagLib::MPEG::File f2(QFile::encodeName(filePath)); // TODO extend also beyond MP3
            if (f2.hasID3v2Tag()) {
                TagLib::ID3v2::Tag * tag = f2.ID3v2Tag();
                TagLib::ID3v2::FrameList l = tag->frameList("TPOS");
                if (!l.isEmpty()) {
                    TagLib::ID3v2::Frame * frame = l.front();
                    const uint tmpPos = QString::fromLatin1(frame->toString().toCString()).section('/', 0, 0).toUInt(); // 1/0
                    if (tmpPos > 0)
                        pos = 1000 * tmpPos;
                }
            }

            QString album = f.tag()->album().toCString(true);
            if (album.isEmpty()) album = tr("Unknown", "unknown album");
            QString genre = f.tag()->genre().toCString(true);
            if (genre.isEmpty()) genre = tr("Unknown", "unknown genre");

            m_tracks.insert(QUrl::fromLocalFile(filePath), {{QStringLiteral("title"), f.tag()->title().toCString(true)},
                                                            {QStringLiteral("artist"), f.tag()->artist().toCString(true)},
                                                            {QStringLiteral("album"), album},
                                                            {QStringLiteral("year"), f.tag()->year()},
                                                            {QStringLiteral("genre"), genre},
                                                            {QStringLiteral("trackNo"), f.tag()->track() + pos},
                                                            {QStringLiteral("length"), f.audioProperties()->lengthInSeconds()}});

            artists.insert(f.tag()->artist().toCString(true));
            albums.insert(album);
            genres.insert(genre);
        }
    }

    m_artists = artists.values();
    std::sort(m_artists.begin(), m_artists.end(), localeAwareCompare);
    m_albums = albums.values();
    std::sort(m_albums.begin(), m_albums.end(), localeAwareCompare);
    m_genres = genres.values();
    std::sort(m_genres.begin(), m_genres.end(), localeAwareCompare);

    qDebug() << "Found" << m_tracks.size() << "tracks";

    emit dbChanged();
    endResetModel();
}

QVariant TrackModel::data(const QModelIndex &index, int role) const
{
    if (index.isValid()) {
        const int row = index.row();
        if (row >= 0 && row < m_tracks.size()) {
            const auto item = std::next(m_tracks.cbegin(), row);
            const auto props = item.value();
            switch (role) {
            case RoleTrackUrl:
                return item.key();
            case RoleTrackFilepath:
                return item.key().toLocalFile();
            case RoleTrackTitle:
                return props.value(QStringLiteral("title"));
            case RoleTrackArtist:
                return props.value(QStringLiteral("artist"));
            case RoleTrackAlbum:
                return props.value(QStringLiteral("album"));
            case RoleTrackYear:
                return props.value(QStringLiteral("year"));
            case RoleTrackGenre:
                return props.value(QStringLiteral("genre"));
            case RoleTrackNumber:
                return props.value(QStringLiteral("trackNo"));
            case RoleTrackLength:
                return props.value(QStringLiteral("length"));
            default:
                Q_UNREACHABLE();
            }
        }
    }
    return {};
}

int TrackModel::rowCount(const QModelIndex &) const
{
    return m_tracks.size();
}

QHash<int, QByteArray> TrackModel::roleNames() const
{
    return m_roleNames;
}
