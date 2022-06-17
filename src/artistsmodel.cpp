#include "artistsmodel.h"

#include <QSet>

#include "musicindexer.h"

ArtistsModel::ArtistsModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, &MusicIndexer::dataChanged, this, &ArtistsModel::parse);
}

void ArtistsModel::parse()
{
  beginResetModel();

  // get list of uniq artists
  QMap<QString, int> artists;
  for (const auto &rec : m_indexer->database()) {
    artists.insert(rec.artist, 0);
  }

  // count each artist's albums
  QMap<QString, int>::iterator it;
  for (it = artists.begin(); it != artists.end(); ++it) {
    QSet<QString> albums;
    for (const auto &rec : m_indexer->database()) {
      if (rec.artist == it.key()) {
        albums.insert(rec.album);
      }
    }
    it.value() = albums.size();

    // finally insert into our datastructure
    m_db.push_back({it.key(), it.value()});
  }

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
  if (!index.isValid())
    return {};

  if (index.row() >= static_cast<int>(m_db.size()))
    return {};

  const auto item = m_db[index.row()];

  switch (static_cast<ArtistRole>(role)) {
  case ArtistsModel::RoleArtist:
    return item.artist;
  case ArtistsModel::RoleNumAlbums:
    return item.numAlbums;
  }

  return {};
}
