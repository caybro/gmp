#include "albumproxymodel.h"
#include "tracksmodel.h"

AlbumProxyModel::AlbumProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
  setSortCaseSensitivity(Qt::CaseInsensitive);
  setFilterCaseSensitivity(Qt::CaseInsensitive);
  setSortLocaleAware(true);

  connect(this, &AlbumProxyModel::sourceModelChanged, this, [this]() {
    connect(sourceModel(), &QAbstractItemModel::dataChanged, this, &AlbumProxyModel::invalidate);
    connect(sourceModel(), &QAbstractItemModel::modelReset, this, &AlbumProxyModel::invalidate);
  });

  sort(0);
}

const QString &AlbumProxyModel::album() const
{
  return m_album;
}

void AlbumProxyModel::setAlbum(const QString &newAlbum)
{
  if (m_album == newAlbum)
    return;
  m_album = newAlbum;
  invalidateFilter();
  emit albumChanged();
}

const QString &AlbumProxyModel::artist() const
{
  return m_artist;
}

void AlbumProxyModel::setArtist(const QString &newArtist)
{
  if (m_artist == newArtist)
    return;
  m_artist = newArtist;
  invalidateFilter();
  emit artistChanged();
}

bool AlbumProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  if (sourceParent.isValid()) {
    return true;
  }

  const QModelIndex &sourceIndex = sourceModel()->index(sourceRow, 0);

  const QString &album = sourceIndex.data(TracksModel::RoleAlbum).toString();
  const QString &artist = sourceIndex.data(TracksModel::RoleArtist).toString();

  return album == m_album && artist == m_artist;
}
