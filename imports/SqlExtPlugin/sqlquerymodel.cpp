#include <QSqlError>
#include <QSqlRecord>
#include <QDebug>
#include <QRandomGenerator>
#include <QSqlQuery>

#include "sqlquerymodel.h"

SqlQueryModel::SqlQueryModel(QObject *parent)
    : QSqlQueryModel(parent)
{
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("sqlext_%1").arg(QRandomGenerator::global()->generate()));
}

SqlQueryModel::~SqlQueryModel()
{
    clear();
    if (m_db.isOpen()) {
        m_db.close();
    }
    QSqlDatabase::removeDatabase(m_db.connectionName());
}

void SqlQueryModel::classBegin()
{
    // do nothing
}

void SqlQueryModel::componentComplete()
{
    if (!m_db.open()) {
        qWarning() << Q_FUNC_INFO << "DB open failed:" << m_db.lastError().text();
        return;
    }

    setQuery(m_query);
}

QString SqlQueryModel::dbFileName() const
{
    return m_db.databaseName();
}

void SqlQueryModel::setDbFileName(const QString &dbFileName)
{
    if (m_db.databaseName() == dbFileName)
        return;

    m_db.setDatabaseName(dbFileName);
    m_db.open();
    emit dbFileNameChanged();
}

bool SqlQueryModel::isValid() const
{
    return m_db.isValid() && m_db.isOpen() && !lastError().isValid();
}

QString SqlQueryModel::errorMessage() const
{
    return lastError().text();
}

QVariant SqlQueryModel::get(int row, const QString &name) const
{
    return data(createIndex(row, record().indexOf(name)));
}

QVariant SqlQueryModel::execHelperQuery(const QString &query) const
{
    QSqlQuery q(query, m_db);
    QVariant result;
    if (!q.isSelect()) {
        qWarning() << "Helper query is not SELECT!";
        return result;
    }
    if (!q.exec()) {
        qWarning() << "Executing helper query failed:" << q.lastError();
        return result;
    }
    if (!q.first()) {
        qWarning() << "Failed positioning helper query at first result:" << q.lastError();
        return result;
    }
    result = q.value(0);
    q.finish();
    return result;
}

QVariantList SqlQueryModel::execListQuery(const QString &query) const
{
    QSqlQuery q(query, m_db);
    QVariantList result;
    if (!q.isSelect()) {
        qWarning() << "List query is not SELECT!";
        return result;
    }
    if (!q.exec()) {
        qWarning() << "Executing list query failed:" << q.lastError();
        return result;
    }

    while (q.next()) {
        result.push_back(q.value(0));
    }
    q.finish();
    return result;
}

QString SqlQueryModel::queryString() const
{
    return m_query;
}

void SqlQueryModel::setQueryString(const QString &query)
{
    if (m_query == query)
        return;

    m_query = query;
    if (m_db.isOpen()) {
        setQuery(m_query, m_db);
        if (lastError().isValid())
             qWarning() << "Error setting model query:" << lastError();
        // TODO update resulting number of rows property
    }
    emit queryChanged();
}
