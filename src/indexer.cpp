#include <QDirIterator>
#include <QFile>
#include <QDebug>
#include <QHashIterator>

#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/mpegfile.h>

#include "indexer.h"

bool localeAwareCompare(const QString &s1, const QString &s2) {
    return s1.localeAwareCompare(s2) < 0;
}

bool localeAwareComparePair(const QPair<QString,QUrl> &s1, const QPair<QString,QUrl> &s2) {
    return s1.first.localeAwareCompare(s2.first) < 0;
}

bool localeAwareComparePair2(const QPair<QString,int> &s1, const QPair<QString,int> &s2) {
    return s1.first.localeAwareCompare(s2.first) < 0;
}

Indexer::Indexer(QObject *parent)
    : QObject(parent)
{
}

QStringList Indexer::rootPaths() const
{
    return m_rootPaths;
}

void Indexer::setRootPaths(const QStringList &rootPaths)
{
    if (m_rootPaths == rootPaths)
        return;

    m_rootPaths = rootPaths;
    emit rootPathsChanged(m_rootPaths);
}

void Indexer::addRootPath(const QString &rootPath)
{
    if (m_rootPaths.contains(rootPath))
        return;

    m_rootPaths.append(rootPath);
    emit rootPathsChanged(m_rootPaths);
}

SongHash Indexer::songs() const
{
    return m_songs;
}

QStringList Indexer::artists() const
{
    return filterArtists();
}

QStringList Indexer::filterArtists(const QString &filter) const
{
    auto tmp = m_artists.values();
    if (!filter.isEmpty()) {
        tmp = tmp.filter(filter, Qt::CaseInsensitive);
    }
    std::sort(tmp.begin(), tmp.end(), localeAwareCompare);
    return tmp;
}

QStringList Indexer::albums() const
{
    return filterAlbums();
}

QStringList Indexer::filterAlbums(const QString &filter) const
{
    auto tmp = m_albums.values();
    if (!filter.isEmpty()) {
        tmp = tmp.filter(filter, Qt::CaseInsensitive);
    }
    std::sort(tmp.begin(), tmp.end(), localeAwareCompare);
    return tmp;
}

QList<QUrl> Indexer::tracks() const
{
    return filterTracks();
}

QList<QUrl> Indexer::filterTracks(const QString &filter) const
{
    QVector<QPair<QString, QUrl>> tmp;
    QHashIterator<QString, QUrl> it(m_tracks);
    while (it.hasNext()) {
        it.next();
        if (it.key().contains(filter, Qt::CaseInsensitive) || filter.isEmpty())
            tmp.append(qMakePair(it.key(), it.value()));
    }

    std::sort(tmp.begin(), tmp.end(), localeAwareComparePair);

    QList<QUrl> result;
    for (const auto &track: qAsConst(tmp))
        result.append(track.second);
    return result;
}

QStringList Indexer::genres() const
{
    return filterGenres();
}

QStringList Indexer::filterGenres(const QString &filter) const
{
    auto tmp = m_genres.values();
    if (!filter.isEmpty()) {
        tmp = tmp.filter(filter, Qt::CaseInsensitive);
    }
    std::sort(tmp.begin(), tmp.end(), localeAwareCompare);
    return tmp;
}

int Indexer::scanAll()
{
    TagLib::FileRef f;
    for (const QString & rootPath: qAsConst(m_rootPaths)) { // TODO watch paths for changes
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
                    const int tmpPos = QString::fromLatin1(frame->toString().toCString()).section('/', 0, 0).toUInt(); // 1/0
                    if (tmpPos > 0)
                        pos = 1000 * tmpPos;
                }
            }

            QString album = f.tag()->album().toCString(true);
            if (album.isEmpty()) album = tr("Unknown album");
            QString genre = f.tag()->genre().toCString(true);
            if (genre.isEmpty()) genre = tr("Unknown genre");

            /*auto it = */m_songs.insert(QUrl::fromLocalFile(filePath), {{QStringLiteral("title"), f.tag()->title().toCString(true)},
                                                                     {QStringLiteral("artist"), f.tag()->artist().toCString(true)},
                                                                     {QStringLiteral("album"), album},
                                                                     {QStringLiteral("year"), f.tag()->year()},
                                                                     {QStringLiteral("genre"), genre},
                                                                     {QStringLiteral("trackNo"), f.tag()->track() + pos},
                                                                     {QStringLiteral("length"), f.audioProperties()->lengthInSeconds()}});

            //qDebug() << "Inserted song:" << it.key() << "\n" << *it;

            m_artists.insert(f.tag()->artist().toCString(true));
            m_albums.insert(album);
            m_tracks.insert(f.tag()->title().toCString(true), QUrl::fromLocalFile(filePath));
            m_genres.insert(genre);
        }
    }
    emit dbChanged();
    return m_songs.count();
}

QVariant Indexer::metadata(const QUrl &fileUrl, const QString &key) const
{
    return m_songs.value(fileUrl).value(key);
}

QString Indexer::artistForAlbum(const QString &album) const
{
    for (const auto &song: qAsConst(m_songs)) {
        if (song.value("album") == album)
            return song.value("artist").toString();
    }

    return QString();
}

int Indexer::yearForAlbum(const QString &album) const
{
    for (const auto &song: qAsConst(m_songs)) {
        if (song.value("album") == album)
            return song.value("year").toInt();
    }

    return -1;
}

QList<QUrl> Indexer::tracksForAlbum(const QString &album) const
{
    QMap<int, QUrl> result;
    QList<QUrl> unsorted;

    QHashIterator<QUrl, QVariantHash> it(m_songs);
    while (it.hasNext()) {
        it.next();
        if (it.value().value("album") == album) {
            if (it.value().value("trackNo").toInt() > 0)
                result.insert(it.value().value("trackNo").toInt(), it.key()); // pre-sort by track number
            else
                unsorted.append(it.key());
        }
    }

    std::sort(unsorted.begin(), unsorted.end());
    return result.values() + unsorted;
}

QStringList Indexer::albumsForArtist(const QString &artist) const
{
    QSet<QString> tmp;

    QHashIterator<QUrl, QVariantHash> it(m_songs);
    while (it.hasNext()) {
        it.next();
        if (it.value().value("artist") == artist) {
            tmp.insert(it.value().value("album").toString());
        }
    }

    QStringList result(tmp.begin(), tmp.end());
    std::sort(result.begin(), result.end(), [this](const QString &a1, const QString &a2) -> bool {
        const int y1 = yearForAlbum(a1);
        const int y2 = yearForAlbum(a2);
        if (y1 == y2)
            return localeAwareCompare(a1, a2);
        else
            return y1 < y2;
    });

    return result;
}

QList<QUrl> Indexer::tracksForGenre(const QString &genre) const
{
    QVector<QPair<QString, QUrl>> tmp;
    QHashIterator<QUrl, QVariantHash> it(m_songs);
    while (it.hasNext()) {
        it.next();
        if (it.value().value("genre") == genre)
            tmp.append(qMakePair(it.value().value("title").toString(), it.key()));
    }

    std::sort(tmp.begin(), tmp.end(), localeAwareComparePair);

    QList<QUrl> result;
    for (const auto &track: qAsConst(tmp))
        result.append(track.second);
    return result;
}

QString Indexer::genreForAlbum(const QString &album) const
{
    const QList<QUrl> tracks = tracksForAlbum(album);
    QHash<QString, int> freqs;
    for (const QUrl &track: tracks) {
        const QString genre = metadata(track, "genre").toString();
        freqs[genre] = freqs.value(genre, 0) + 1;
    }

    QVector<QPair<QString,int>> tmp;
    QHashIterator<QString, int> it(freqs);
    while (it.hasNext()) {
        it.next();
        tmp.append(qMakePair(it.key(), it.value()));
    }
    std::sort(tmp.begin(), tmp.end(), localeAwareComparePair2);
    return tmp.constFirst().first;
}

int Indexer::albumLength(const QString &album) const
{
    int result = 0;

    QHashIterator<QUrl, QVariantHash> it(m_songs);
    while (it.hasNext()) {
        it.next();
        if (it.value().value("album") == album) {
            result += it.value().value("length").toInt();
        }
    }

    return result;
}

QUrl Indexer::coverArtForFile(const QUrl &fileUrl) const
{
    const QString localFile = fileUrl.toLocalFile();
    const QString result = localFile + QStringLiteral(".png");
    if (QFile::exists(result))
        return QUrl::fromLocalFile(result);

    TagLib::MPEG::File f(QFile::encodeName(localFile)); // TODO extend also beyond MP3
    if (f.hasID3v2Tag()) {
        TagLib::ID3v2::Tag *tag = f.ID3v2Tag();
        TagLib::ID3v2::FrameList l = tag->frameList("APIC");
        if (l.isEmpty())
            return QUrl();

        TagLib::ID3v2::AttachedPictureFrame *f = static_cast<TagLib::ID3v2::AttachedPictureFrame *>(l.front());
        if (!f)
            return QUrl();

        QImage image;
        image.loadFromData((const uchar *) f->picture().data(), f->picture().size());
        image.save(result);
        return QUrl::fromLocalFile(result);
    }

    return QUrl();
}

QUrl Indexer::coverArtForAlbum(const QString &album) const
{
    QUrl result;
    const auto tracks = tracksForAlbum(album);
    for (const QUrl &track: tracks) {
        result = coverArtForFile(track);
        if (!result.isEmpty())
            break;
    }

    if (result.isEmpty())
        result = QStringLiteral("qrc:/icons/ic_album_48px.svg");

    return result;
}
