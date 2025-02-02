#include "tracksmodel.h"

#include "musicindexer.h"

#include <QImage>

#include <algorithm>

TracksModel::TracksModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, qOverload<>(&MusicIndexer::dataChanged), this, [this]() {
    beginResetModel();
    endResetModel();
  });
  connect(m_indexer, qOverload<int>(&MusicIndexer::dataChanged), this, [this](int row) {
    const auto idx = index(row);
    emit dataChanged(idx, idx);
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
                                             {TrackRole::RoleLength, QByteArrayLiteral("length")},
                                             {TrackRole::RoleCoverImage, QByteArrayLiteral("coverImage")}};

  return roleNames;
}

int TracksModel::rowCount(const QModelIndex &) const
{
  return static_cast<int>(m_indexer->database().size());
}

QVariant TracksModel::data(const QModelIndex &index, int role) const
{
  if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid
                             | QAbstractItemModel::CheckIndexOption::ParentIsInvalid))
    return {};

  auto const &db = m_indexer->database();

  const auto &item = db[index.row()];

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
  case TracksModel::RoleCoverImage:
    return m_indexer->coverArtImageForFile(item.path);
  }

  return {};
}

QJsonObject TracksModel::getMetadata(const QUrl &url) const
{
  const auto &db = m_indexer->database();
  const auto row = std::find_if(db.cbegin(), db.cend(), [url](const auto &rec) { return rec.url == url; });
  if (row == db.cend())
    return {};
  const auto rowIndex = std::distance(db.cbegin(), row);

  const auto idx = index(rowIndex);
  if (!checkIndex(idx, QAbstractItemModel::CheckIndexOption::IndexIsValid))
    return {};

  QJsonObject result;
  QHashIterator<int, QByteArray> i(roleNames());
  while (i.hasNext()) {
    i.next();
    if (i.key() == TracksModel::RoleCoverImage)
      continue;
    result.insert(i.value(), QJsonValue::fromVariant(data(idx, i.key())));
  }
  return result;
}
