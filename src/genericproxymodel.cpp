#include "genericproxymodel.h"

GenericProxyModel::GenericProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
  setSortCaseSensitivity(Qt::CaseInsensitive);
  setFilterCaseSensitivity(Qt::CaseInsensitive);
  setSortLocaleAware(true);

  connect(this, &GenericProxyModel::sourceModelChanged, this, [this]() {
    connect(sourceModel(), &QAbstractItemModel::dataChanged, this, &GenericProxyModel::invalidate);
    connect(sourceModel(), &QAbstractItemModel::modelReset, this, &GenericProxyModel::invalidate);
  });

  connect(this, &GenericProxyModel::layoutChanged, this, &GenericProxyModel::countChanged);

  sort(0);
}

QString GenericProxyModel::filterString() const
{
  return m_filterString;
}

void GenericProxyModel::setFilterString(const QString &filterString)
{
  if (m_filterString == filterString)
    return;

  m_filterString = filterString;
  setFilterFixedString(m_filterString);
  emit filterStringChanged(m_filterString);
  emit countChanged();
}
