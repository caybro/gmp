#pragma once

#include <QSortFilterProxyModel>

class TracksModel;

class AlbumProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT

  Q_PROPERTY(QString album READ album WRITE setAlbum NOTIFY albumChanged REQUIRED)
  Q_PROPERTY(QString artist READ artist WRITE setArtist NOTIFY artistChanged REQUIRED)

 public:
  AlbumProxyModel(QObject *parent = nullptr);

  const QString &album() const;
  void setAlbum(const QString &newAlbum);

  const QString &artist() const;
  void setArtist(const QString &newArtist);

 protected:
  bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

 signals:
  void albumChanged();
  void artistChanged();

 private:
  QString m_album;
  QString m_artist;
};
