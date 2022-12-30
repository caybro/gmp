#include "artistsmodel.h"

#include <unordered_set>

#include "musicindexer.h"

ArtistsModel::ArtistsModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, qOverload<>(&MusicIndexer::dataChanged), this, &ArtistsModel::parse);
}

void ArtistsModel::parse()
{
  beginResetModel();
  m_db.clear();

  // get list of uniq artists
  std::unordered_set<QString> artists;
  for (const auto &rec : std::as_const(m_indexer->database())) {
    artists.emplace(rec.artist);
  }

  m_db.reserve(artists.size());

  // count each artist's albums
  for (const auto &artist : std::as_const(artists)) {
    std::unordered_set<QString> albums;
    for (const auto &rec : std::as_const(m_indexer->database())) {
      if (rec.artist == artist) {
        albums.insert(rec.album);
      }
    }

    // finally insert into our datastructure
    m_db.push_back({artist, static_cast<int>(albums.size())});
  }

  emit countChanged();
  endResetModel();
}

QHash<int, QByteArray> ArtistsModel::roleNames() const
{
  static QHash<int, QByteArray> roleNames = {{ArtistRole::RoleArtist, QByteArrayLiteral("artist")},
                                             {ArtistRole::RoleNumAlbums, QByteArrayLiteral("numAlbums")}};

  return roleNames;
}

int ArtistsModel::rowCount(const QModelIndex &) const
{
  return m_db.size();
}

QVariant ArtistsModel::data(const QModelIndex &index, int role) const
{
  if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid
                             | QAbstractItemModel::CheckIndexOption::ParentIsInvalid))
    return {};

  const auto &item = m_db[index.row()];

  switch (static_cast<ArtistRole>(role)) {
  case ArtistsModel::RoleArtist:
    return item.artist;
  case ArtistsModel::RoleNumAlbums:
    return item.numAlbums;
  }

  return {};
}

int ArtistsModel::count() const
{
  return rowCount();
}
