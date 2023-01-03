#include "musicindexer.h"

#include <taglib/attachedpictureframe.h>
#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>

#include <QDebug>
#include <QDirIterator>
#include <QElapsedTimer>
#include <QImage>
#include <QMimeDatabase>

#include <algorithm>

namespace {
TagLib::String toTString(const QString &str)
{
  return {str.toUtf8().constData(), TagLib::String::UTF8};
}

QString fromTString(const TagLib::String &string) {
  return QString::fromStdString(string.to8Bit(true));
}
} // namespace

MusicIndexer::MusicIndexer(QObject *parent)
    : QObject{parent}
{}

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

      f = TagLib::FileRef(QFile::encodeName(filePath), true, TagLib::AudioProperties::Fast);

      uint pos = 0;
      TagLib::MPEG::File f2(QFile::encodeName(filePath)); // TODO extend also beyond MP3
      if (f2.hasID3v2Tag()) {
        const auto l = f2.ID3v2Tag()->frameList("TPOS");
        if (!l.isEmpty()) {
          const int tmpPos = l.front()->toString().split('/').front().toInt();
          if (tmpPos > 0)
            pos = 1000 * tmpPos;
        }
      }

      const auto tag = f.tag();

      QString album = fromTString(tag->album());
      if (album.isEmpty())
        album = tr("Unknown album");
      QString genre = fromTString(tag->genre());
      if (genre.isEmpty())
        genre = tr("Unknown genre");

      MusicRecord rec;
      rec.path = filePath;
      rec.url = QUrl::fromLocalFile(filePath);
      rec.title = fromTString(tag->title());
      rec.artist = fromTString(tag->artist());
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
      m_db.push_back(std::move(rec));
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

  std::transform(m_db.cbegin(), m_db.cend(), std::back_inserter(result),
                 [](const auto &rec) { return rec.url; });

  return result;
}

QList<QUrl> MusicIndexer::tracksByAlbum(const QString &album, bool ordered) const
{
  std::vector<MusicRecord> tracks;

  for (const auto &rec : std::as_const(m_db)) {
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

  for (const auto &rec : std::as_const(m_db)) {
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

  for (const auto &rec : std::as_const(m_db)) {
    if (rec.artist == artist)
      result.append(rec.url);
  }

  return result;
}

int MusicIndexer::tracksDuration(const QList<QUrl> &urls) const
{
  int result = 0;

  for (const auto &url : urls) {
    const auto track = std::find_if(m_db.cbegin(), m_db.cend(),
                                    [url](const MusicRecord &rec) { return rec.url == url; });
    if (track != std::cend(m_db))
      result += track->length;
  }

  return result;
}

int MusicIndexer::albumTracksDuration(const QString &album) const
{
  int result = 0;

  for (const auto &rec : std::as_const(m_db)) {
    if (rec.album == album)
      result += rec.length;
  }

  return result;
}

QImage MusicIndexer::coverArtImageForFile(const QString &file) const
{
  TagLib::MPEG::File f(QFile::encodeName(file)); // TODO extend also beyond MP3
  if (f.hasID3v2Tag()) {
    const auto tag = f.ID3v2Tag();
    const auto l = tag->frameList("APIC");
    if (l.isEmpty())
      return {};

    const auto frame = static_cast<TagLib::ID3v2::AttachedPictureFrame *>(l.front());
    if (!frame)
      return {};

    QImage image;
    image.loadFromData((const uchar *) frame->picture().data(), frame->picture().size());
    return image;
  }
  return {};
}

QUrl MusicIndexer::coverArtForFile(const QUrl &fileUrl) const
{
  const QString localFile = fileUrl.toLocalFile();
  const QString result = localFile + QStringLiteral(".png");
  if (QFile::exists(result))
    return QUrl::fromLocalFile(result);

  const auto image = coverArtImageForFile(localFile);
  if (image.isNull())
    return {};

  image.save(result);
  return QUrl::fromLocalFile(result);
}

QUrl MusicIndexer::coverArtForAlbum(const QString &album) const
{
  const auto tracks = tracksByAlbum(album);

  // find first existing cover pic from the album
  QUrl result;
  for (const auto &track : tracks) {
    result = coverArtForFile(track);
    if (!result.isEmpty())
      return result;
  }

  // fallback
  if (result.isEmpty())
    result = QStringLiteral("qrc:/icons/ic_album_48px.svg");

  return result;
}

bool MusicIndexer::saveMetadata(const QUrl &url, const QString &title, const QString &artist, const QString &album,
                                int year, const QString &genre)
{
  // save metadata to file
  auto f = TagLib::FileRef(QFile::encodeName(url.toLocalFile()));
  f.tag()->setTitle(toTString(title));
  f.tag()->setArtist(toTString(artist));
  f.tag()->setAlbum(toTString(album));
  f.tag()->setYear(year);
  f.tag()->setGenre(toTString(genre));
  const bool result = f.save();

  qDebug() << "Saved metadata for url:" << url << "; status:" << result;

  // replace the record
  if (result) {
    const auto rec = std::find_if(m_db.cbegin(), m_db.cend(), [url](const MusicRecord &rec) { return rec.url == url; });
    if (rec != std::cend(m_db)) {
      MusicRecord newRecord{*rec};
      newRecord.title = title;
      newRecord.artist = artist;
      newRecord.album = album;
      newRecord.year = year;
      newRecord.genre = genre;

      std::replace(m_db.begin(), m_db.end(), *rec, std::move(newRecord));

      const auto row = std::distance(m_db.cbegin(), rec);
      emit dataChanged(row);
    }
  }

  return result;
}

bool MusicIndexer::saveAlbumMetadata(const QString &album, const QString &artist, const QString &genre, int year,
                                     const QUrl &albumCover)
{
  qDebug() << "!! SAVE ALBUM METADATA" << album << artist << "; cover URL:" << albumCover;

  bool result = false;
  TagLib::FileRef f;
  QMimeDatabase mime;
  const auto coverFile = albumCover.toLocalFile();
  const auto tracks = tracksByAlbum(album);

  for (const auto &track : tracks) {
    // save metadata
    f = TagLib::FileRef(QFile::encodeName(track.toLocalFile()));
    f.tag()->setGenre(toTString(genre));
    f.tag()->setYear(year);
    result = f.save();

    if (!result) {
      qWarning() << "Failed saving ID3 tag to file" << track.toLocalFile();
      continue;
    }

    // replace the record
    const auto rec = std::find_if(m_db.cbegin(), m_db.cend(),
                                  [track](const MusicRecord &rec) { return rec.url == track; });
    if (result && rec != std::cend(m_db)) {
      MusicRecord newRecord{*rec};
      newRecord.year = year;
      newRecord.genre = genre;

      std::replace(m_db.begin(), m_db.end(), *rec, std::move(newRecord));

      const auto row = std::distance(m_db.cbegin(), rec);
      emit dataChanged(row);
    }

    if (albumCover.isEmpty())
      continue;

    // remove old cover file
    const auto oldCover = track.toLocalFile() + QStringLiteral(".png");
    if (QFile::exists(oldCover)) {
      qDebug() << "Found existing cover file, removing:" << oldCover;
      QFile::remove(oldCover);
    }

    // save cover to ID3 tag
    TagLib::MPEG::File ff(QFile::encodeName(track.toLocalFile())); // TODO extend also beyond MP3
    TagLib::ID3v2::Tag *tag = ff.ID3v2Tag(true);
    QFile reader(coverFile);
    if (reader.open(QFile::ReadOnly)) {
      tag->removeFrames("APIC"); // drop old frames of this type -> replace cover
      const auto data = reader.readAll();
      auto frame = new TagLib::ID3v2::AttachedPictureFrame;
      frame->setType(TagLib::ID3v2::AttachedPictureFrame::FrontCover);
      frame->setMimeType(toTString(mime.mimeTypeForFile(coverFile).name()));
      frame->setPicture(TagLib::ByteVector(data.constData(), data.size()));
      tag->addFrame(frame);
      ff.save();
      reader.close();
    }
  }

  emit albumCoverArtChanged(album, artist);

  qDebug() << "Saved metadata for album:" << album << "and artist:" << artist << "; status:" << result;
  return result;
}
