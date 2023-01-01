#include "albumsmodel.h"

#include <unordered_map>

#include "musicindexer.h"

AlbumsModel::AlbumsModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, qOverload<>(&MusicIndexer::dataChanged), this, &AlbumsModel::parse);
}

void AlbumsModel::parse()
{
  beginResetModel();
  m_db.clear();

  // get list of unique albums
  std::unordered_map<QString, QString> albums; // album,artist
  for (const auto &rec : m_indexer->database()) {
    albums.try_emplace(rec.album, rec.artist);
  }

  m_db.reserve(albums.size());

  // get the album's tracks
  for (const auto &[album, artist] : std::as_const(albums)) {
    std::vector<MusicRecord> tracks;
    for (const auto &rec : std::as_const(m_indexer->database())) {
      if (rec.album == album && rec.artist == artist) {
        tracks.emplace_back(rec);
      }
    }

    // assemble the new album
    Album a;
    a.album = album;
    a.artist = artist;
    if (!tracks.empty()) {
      const auto firstTrack = tracks.cbegin();
      a.year = firstTrack->year;
      a.numTracks = tracks.size();
      a.genre = firstTrack->genre;
      a.coverImage = m_indexer->coverArtImageForFile(firstTrack->path);
    }

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
                                             {AlbumRole::RoleGenre, QByteArrayLiteral("genre")},
                                             {AlbumRole::RoleCoverImage, QByteArrayLiteral("coverImage")}};

  return roleNames;
}

int AlbumsModel::rowCount(const QModelIndex &) const
{
  return m_db.size();
}

QVariant AlbumsModel::data(const QModelIndex &index, int role) const
{
  if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid
                             | QAbstractItemModel::CheckIndexOption::ParentIsInvalid))
    return {};

  const auto &item = m_db[index.row()];

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
  case AlbumsModel::RoleCoverImage:
    return item.coverImage;
  }

  return {};
}

int AlbumsModel::count() const
{
  return rowCount();
}
