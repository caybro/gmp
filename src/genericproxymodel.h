#pragma once

#include <QSortFilterProxyModel>

class GenericProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT

  Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)

  Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

 public:
  GenericProxyModel(QObject *parent = nullptr);

 signals:
  void filterStringChanged(const QString &filterString);
  void countChanged();

 private:
  QString filterString() const;
  void setFilterString(const QString &filterString);
  QString m_filterString;
};
