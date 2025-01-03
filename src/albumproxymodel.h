#pragma once

#include <QImage>
#include <QSortFilterProxyModel>

class TracksModel;

class AlbumProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT

  Q_PROPERTY(QString album READ album WRITE setAlbum NOTIFY albumChanged REQUIRED)
  Q_PROPERTY(QString artist READ artist WRITE setArtist NOTIFY artistChanged REQUIRED)
  Q_PROPERTY(QString genre READ genre NOTIFY metadataChanged)
  Q_PROPERTY(int year READ year NOTIFY metadataChanged)
  Q_PROPERTY(QImage coverImage READ coverImage NOTIFY metadataChanged)
  Q_PROPERTY(int tracksDuration READ tracksDuration NOTIFY metadataChanged)

 public:
  AlbumProxyModel(QObject *parent = nullptr);

 protected:
  bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

 signals:
  void albumChanged();
  void artistChanged();
  void metadataChanged();

 private:
  const QString &album() const;
  void setAlbum(const QString &newAlbum);
  QString m_album;

  const QString &artist() const;
  void setArtist(const QString &newArtist);
  QString m_artist;

  QString genre() const;
  int year() const;
  QImage coverImage() const;
  int tracksDuration() const;
};
