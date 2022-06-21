#include "musicindexer.h"

#include <taglib/attachedpictureframe.h>
#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>

#include <QDebug>
#include <QDirIterator>
#include <QElapsedTimer>
#include <QImage>

#include <algorithm>

MusicIndexer::MusicIndexer(QObject *parent)
    : QObject{parent}
{
}

QStringList MusicIndexer::rootPaths() const
{
  return m_rootPaths;
}

void MusicIndexer::setRootPaths(const QStringList &rootPaths)
{
  if (m_rootPaths == rootPaths)
    return;

  m_rootPaths = rootPaths;
  emit rootPathsChanged(m_rootPaths);
}

void MusicIndexer::addRootPath(const QString &rootPath)
{
  if (m_rootPaths.contains(rootPath))
    return;

  m_rootPaths.append(rootPath);
  emit rootPathsChanged(m_rootPaths);
}

bool MusicIndexer::isIndexing() const
{
  return m_indexing;
}

void MusicIndexer::setIndexing(bool indexing)
{
  if (m_indexing == indexing)
    return;

  m_indexing = indexing;
  emit isIndexingChanged(m_indexing);
}

void MusicIndexer::parse(bool incremental)
{
  setIndexing(true);
#ifdef QT_DEBUG
  qDebug() << "!!! INDEXER start parsing...";
  QElapsedTimer timer;
  timer.start();
#endif

  if (!incremental)
    m_db.clear();

  TagLib::FileRef f;
  for (const auto &rootPath : qAsConst(m_rootPaths)) { // TODO watch paths for changes
    QDirIterator it(rootPath,
                    {QStringLiteral("*.mp3"), QStringLiteral("*.ogg"), QStringLiteral("*.oga"), QStringLiteral("*.wma"),
                     QStringLiteral("*.wav"), QStringLiteral("*.flac"), QStringLiteral("*.m4a"),
                     QStringLiteral("*.aac")}, // FIXME find out dynamically
                    QDir::Files | QDir::NoDotAndDotDot | QDir::Readable, QDirIterator::Subdirectories);
    while (it.hasNext()) {
      const QString filePath = it.next();
      //qDebug() << "Found audio file:" << filePath;

      f = TagLib::FileRef(QFile::encodeName(filePath));

      uint pos = 0;
      TagLib::MPEG::File f2(QFile::encodeName(filePath)); // TODO extend also beyond MP3
      if (f2.hasID3v2Tag()) {
        auto tag = f2.ID3v2Tag();
        const auto l = tag->frameList("TPOS");
        if (!l.isEmpty()) {
          const auto frame = l.front();
          const int tmpPos
              = QString::fromLatin1(frame->toString().toCString()).section(QLatin1Char('/'), 0, 0).toUInt(); // 1/0
          if (tmpPos > 0)
            pos = 1000 * tmpPos;
        }
      }

      const auto tag = f.tag();

      QString album = tag->album().toCString(true);
      if (album.isEmpty())
        album = tr("Unknown album");
      QString genre = tag->genre().toCString(true);
      if (genre.isEmpty())
        genre = tr("Unknown genre");

      MusicRecord rec;
      rec.path = filePath;
      rec.url = QUrl::fromLocalFile(filePath);
      rec.title = tag->title().toCString(true);
      rec.artist = tag->artist().toCString(true);
      rec.album = album;
      rec.year = tag->year();
      rec.genre = genre;
      rec.trackNo = tag->track() + pos;
      rec.length = f.audioProperties()->lengthInSeconds();

      if (incremental) {
        // erase old record
        const auto old = std::find_if(m_db.cbegin(), m_db.cend(),
                                      [&](const MusicRecord &rec) { return rec.path == filePath; });
        if (old != std::cend(m_db)) {
          m_db.erase(old);
        }
      }
      m_db.push_back(rec);
    }
  }

  setIndexing(false);
  emit dataChanged();
#ifdef QT_DEBUG
  qDebug() << "!!! INDEXER took" << timer.elapsed() << "ms";
  qDebug() << "!!! INDEXER found" << m_db.size() << "files";
#endif
}

const MusicDatabase &MusicIndexer::database() const
{
  return m_db;
}

QList<QUrl> MusicIndexer::allTracks() const
{
  QList<QUrl> result;
  result.reserve(m_db.size());

  for (const auto &rec : m_db) {
    result.append(rec.url);
  }

  return result;
}

QList<QUrl> MusicIndexer::tracksByAlbum(const QString &album, bool ordered) const
{
  std::vector<MusicRecord> tracks;

  for (const auto &rec : m_db) {
    if (rec.album == album)
      tracks.push_back(rec);
  }

  if (ordered) {
    std::sort(tracks.begin(), tracks.end(), [](const auto &t1, const auto &t2) { return t1.trackNo < t2.trackNo; });
  }

  QList<QUrl> result;
  result.reserve(tracks.size());
  std::transform(tracks.cbegin(), tracks.cend(), std::back_inserter(result),
                 [](const auto &track) { return track.url; });

  return result;
}

QList<QUrl> MusicIndexer::tracksByGenre(const QString &genre, bool ordered) const
{
  std::vector<MusicRecord> tracks;

  for (const auto &rec : m_db) {
    if (rec.genre == genre)
      tracks.push_back(rec);
  }

  if (ordered) {
    std::sort(tracks.begin(), tracks.end(),
              [](const auto &t1, const auto &t2) { return t1.title.localeAwareCompare(t2.title) < 0; });
  }

  QList<QUrl> result;
  result.reserve(tracks.size());
  std::transform(tracks.cbegin(), tracks.cend(), std::back_inserter(result),
                 [](const auto &track) { return track.url; });

  return result;
}

QList<QUrl> MusicIndexer::tracksByArtist(const QString &artist) const
{
  QList<QUrl> result;
  result.reserve(m_db.size());

  for (const auto &rec : m_db) {
    if (rec.artist == artist)
      result.append(rec.url);
  }

  return result;
}

int MusicIndexer::tracksDuration(const QList<QUrl> &urls) const
{
  int result = 0;

  for (const auto &url : urls) {
    const auto track = std::find_if(m_db.cbegin(), m_db.cend(), [url](MusicRecord rec) { return rec.url == url; });
    if (track != std::cend(m_db))
      result += track->length;
  }

  return result;
}

int MusicIndexer::albumTracksDuration(const QString &album) const
{
  int result = 0;

  for (const auto &rec : m_db) {
    if (rec.album == album)
      result += rec.length;
  }

  return result;
}

QUrl MusicIndexer::coverArtForFile(const QUrl &fileUrl) const
{
  const QString localFile = fileUrl.toLocalFile();
  const QString result = localFile + QStringLiteral(".png");
  if (QFile::exists(result))
    return QUrl::fromLocalFile(result);

  TagLib::MPEG::File f(QFile::encodeName(localFile)); // TODO extend also beyond MP3
  if (f.hasID3v2Tag()) {
    const auto tag = f.ID3v2Tag();
    const auto l = tag->frameList("APIC");
    if (l.isEmpty())
      return {};

    auto frame = static_cast<TagLib::ID3v2::AttachedPictureFrame *>(l.front());
    if (!frame)
      return {};

    QImage image;
    image.loadFromData((const uchar *) frame->picture().data(), frame->picture().size());
    image.save(result);
    return QUrl::fromLocalFile(result);
  }

  return {};
}

QUrl MusicIndexer::coverArtForAlbum(const QString &album) const
{
  QList<QUrl> tracks = tracksByAlbum(album);

  QUrl result;
  for (const QUrl &track : qAsConst(tracks)) {
    result = coverArtForFile(track);
    if (!result.isEmpty())
      break;
  }

  if (result.isEmpty())
    result = QStringLiteral("qrc:/icons/ic_album_48px.svg");

  return result;
}
