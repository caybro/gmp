#include <QSqlError>
#include <QDebug>

#include "sqltablemodel.h"

SqlTableModel::SqlTableModel(QObject *parent)
    : QSqlTableModel(parent)
{
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
}

SqlTableModel::~SqlTableModel()
{
    clear();
    if (m_db.isOpen()) {
        m_db.close();
    }
    QSqlDatabase::removeDatabase(m_db.connectionName());
}

void SqlTableModel::classBegin()
{
    // do nothing
}

void SqlTableModel::componentComplete()
{
    if (!m_db.open()) {
        qWarning() << Q_FUNC_INFO << "DB open failed:" << m_db.lastError().text();
        return;
    }

    qWarning() << Q_FUNC_INFO << "Trying to select table:" << tableName();

    if (!select())
        qWarning() << Q_FUNC_INFO << errorMessage();
}

QString SqlTableModel::dbFileName() const
{
    return m_db.databaseName();
}

void SqlTableModel::setDbFileName(const QString &dbFileName)
{
    if (m_db.databaseName() == dbFileName)
        return;

    m_db.setDatabaseName(dbFileName);
    emit dbFileNameChanged();
}

void SqlTableModel::setTable(const QString &name)
{
    if (tableName() == name)
        return;

    QSqlTableModel::setTable(name);
    emit tableNameChanged();
}

void SqlTableModel::setFilter(const QString &filt)
{
    if (filt == filter())
        return;

    QSqlTableModel::setFilter(filt);
    emit filterChanged();
}

bool SqlTableModel::isValid() const
{
    return m_db.isValid() && m_db.isOpen() && !lastError().isValid();
}

QString SqlTableModel::errorMessage() const
{
    return lastError().text();
}
