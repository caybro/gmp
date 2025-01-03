#include "genresmodel.h"

#include <unordered_set>

#include "musicindexer.h"
#include "duplicatetracker.h"

GenresModel::GenresModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, qOverload<>(&MusicIndexer::dataChanged), this, &GenresModel::parse);
}

void GenresModel::parse()
{
  beginResetModel();
  m_db.clear();

  KDToolBox::DuplicateTracker<QString> genres;
  for (const auto &rec : std::as_const(m_indexer->database())) {
    genres.hasSeen(rec.genre);
  }

  m_db.reserve(genres.set().size());

  for (const auto &genre : std::as_const(genres.set())) {
    const auto numTracks = std::count_if(m_indexer->database().cbegin(), m_indexer->database().cend(),
                                         [genre](const auto &rec) { return rec.genre == genre; });
    m_db.emplace_back(genre, static_cast<uint>(numTracks));
  }

  endResetModel();
  emit countChanged();
}

QHash<int, QByteArray> GenresModel::roleNames() const
{
  static QHash<int, QByteArray> roleNames = {{GenresModel::RoleGenre, QByteArrayLiteral("genre")},
                                             {GenresModel::RoleNumTracks, QByteArrayLiteral("numTracks")}};

  return roleNames;
}

int GenresModel::rowCount(const QModelIndex &) const
{
  return m_db.size();
}

QVariant GenresModel::data(const QModelIndex &index, int role) const
{
  if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid
                             | QAbstractItemModel::CheckIndexOption::ParentIsInvalid))
    return {};

  const auto &item = m_db[index.row()];

  switch (static_cast<GenreRole>(role)) {
  case GenresModel::RoleGenre:
    return item.genre;
  case GenresModel::RoleNumTracks:
    return item.numTracks;
  }

  return {};
}
