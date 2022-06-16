#pragma once

#include <QAbstractListModel>

#include "musicindexer.h"

class ArtistsModel : public QAbstractListModel
{
  Q_OBJECT

 public:
  explicit ArtistsModel(QObject *parent = nullptr);

  void setDatabase(const std::vector<MusicRecord> &db);

 private:
};
