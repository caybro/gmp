#include "albumsmodel.h"

#include <QSet>

#include "musicindexer.h"

AlbumsModel::AlbumsModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, &MusicIndexer::dataChanged, this, &AlbumsModel::parse);
}

void AlbumsModel::parse()
{
  beginResetModel();
  m_db.clear();

  // get list of unique albums
  QMap<QString, QString> albums; // album,artist
  for (const auto &rec : m_indexer->database()) {
    albums.insert(rec.album, rec.artist);
  }

  // get the album's tracks
  QMap<QString, QString>::iterator it;
  for (it = albums.begin(); it != albums.end(); ++it) {
    QSet<MusicRecord> tracks;
    for (const auto &rec : m_indexer->database()) {
      if (rec.album == it.key() && rec.artist == it.value()) {
        tracks.insert(rec);
      }
    }

    // assemble the new album
    Album a;
    a.album = it.key();
    a.artist = it.value();
    const auto firstTrack = *tracks.constBegin();
    a.year = firstTrack.year;
    a.numTracks = tracks.size();
    a.genre = firstTrack.genre;

    // finally insert into our datastructure
    m_db.push_back(std::move(a));
  }

  emit countChanged();
  endResetModel();
}

QHash<int, QByteArray> AlbumsModel::roleNames() const
{
  static QHash<int, QByteArray> roleNames = {{AlbumRole::RoleAlbum, QByteArrayLiteral("album")},
                                             {AlbumRole::RoleArtist, QByteArrayLiteral("artist")},
                                             {AlbumRole::RoleYear, QByteArrayLiteral("year")},
                                             {AlbumRole::RoleNumTracks, QByteArrayLiteral("numTracks")},
                                             {AlbumRole::RoleGenre, QByteArrayLiteral("genre")}};

  return roleNames;
}

int AlbumsModel::rowCount(const QModelIndex &) const
{
  return m_db.size();
}

QVariant AlbumsModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return {};

  if (index.row() >= static_cast<int>(m_db.size()))
    return {};

  const auto item = m_db[index.row()];

  switch (static_cast<AlbumRole>(role)) {
  case AlbumsModel::RoleAlbum:
    return item.album;
  case AlbumsModel::RoleArtist:
    return item.artist;
  case AlbumsModel::RoleYear:
    return item.year;
  case AlbumsModel::RoleNumTracks:
    return item.numTracks;
  case AlbumsModel::RoleGenre:
    return item.genre;
  }

  return {};
}

int AlbumsModel::count() const
{
  return rowCount();
}
