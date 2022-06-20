#include "tracksmodel.h"

#include "musicindexer.h"

#include <algorithm>

TracksModel::TracksModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, &MusicIndexer::dataChanged, this, [&]() {
    beginResetModel();
    endResetModel();
  });
}

QHash<int, QByteArray> TracksModel::roleNames() const
{
  static QHash<int, QByteArray> roleNames = {{TrackRole::RolePath, QByteArrayLiteral("path")},
                                             {TrackRole::RoleUrl, QByteArrayLiteral("url")},
                                             {TrackRole::RoleTitle, QByteArrayLiteral("title")},
                                             {TrackRole::RoleArtist, QByteArrayLiteral("artist")},
                                             {TrackRole::RoleAlbum, QByteArrayLiteral("album")},
                                             {TrackRole::RoleYear, QByteArrayLiteral("year")},
                                             {TrackRole::RoleGenre, QByteArrayLiteral("genre")},
                                             {TrackRole::RoleTrackNo, QByteArrayLiteral("trackNo")},
                                             {TrackRole::RoleLength, QByteArrayLiteral("length")}};

  return roleNames;
}

int TracksModel::rowCount(const QModelIndex &) const
{
  return static_cast<int>(m_indexer->database().size());
}

QVariant TracksModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return {};

  auto const &db = m_indexer->database();

  if (index.row() >= static_cast<int>(db.size()))
    return {};

  const auto item = db[index.row()];

  switch (static_cast<TrackRole>(role)) {
  case TracksModel::RolePath:
    return item.path;
  case TracksModel::RoleUrl:
    return item.url;
  case TracksModel::RoleTitle:
    return item.title;
  case TracksModel::RoleArtist:
    return item.artist;
  case TracksModel::RoleAlbum:
    return item.album;
  case TracksModel::RoleYear:
    return item.year;
  case TracksModel::RoleGenre:
    return item.genre;
  case TracksModel::RoleTrackNo:
    return item.trackNo;
  case TracksModel::RoleLength:
    return item.length;
  }

  return {};
}

QJsonObject TracksModel::getMetadata(const QUrl &url) const
{
  const auto &db = m_indexer->database();
  const auto row = std::find_if(db.cbegin(), db.cend(), [url](MusicRecord rec) { return rec.url == url; });
  if (row == db.cend())
    return {};
  const auto rowIndex = std::distance(db.cbegin(), row);

  const auto idx = index(rowIndex);
  if (!idx.isValid() || !checkIndex(idx))
    return {};

  QJsonObject result;
  QHashIterator<int, QByteArray> i(roleNames());
  while (i.hasNext()) {
    i.next();
    result.insert(i.value(), QJsonValue::fromVariant(data(idx, i.key())));
  }
  return result;
}
