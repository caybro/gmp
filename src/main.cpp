#ifdef QT_NO_SYSTEMTRAYICON
#include <QGuiApplication>
#else
#include <QApplication>
#endif

#include <QIcon>
#include <QLibraryInfo>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTouchDevice>
#include <QTranslator>

#include "albumproxymodel.h"
#include "albumsmodel.h"
#include "artistsmodel.h"
#include "directimage.h"
#include "genericproxymodel.h"
#include "genresmodel.h"
#include "musicindexer.h"
#include "tracksmodel.h"

int main(int argc, char *argv[])
{
  qputenv("QT_IM_MODULE", QByteArrayLiteral("qtvirtualkeyboard"));

  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

#ifdef QT_NO_SYSTEMTRAYICON
  QGuiApplication app(argc, argv);
#else
  QApplication app(argc, argv);
  app.setQuitOnLastWindowClosed(false);
#endif

  if (QTouchDevice::devices().isEmpty()) {
    qputenv("QT_QUICK_CONTROLS_HOVER_ENABLED", QByteArrayLiteral("1"));
  }

  QLoggingCategory::setFilterRules(QStringLiteral("*.debug=true\nqt.*.debug=false"));

  app.setOrganizationName(QStringLiteral("caybro"));
  app.setApplicationDisplayName(QStringLiteral("G Music Player"));
  app.setApplicationVersion(QStringLiteral("0.0.2"));

  app.setWindowIcon(QIcon(QStringLiteral(":/icons/ic_library_music_48px.svg")));

  QTranslator qtTranslator;
  qtTranslator.load(QLocale::system(), QStringLiteral("qt_"), QString(),
                    QLibraryInfo::location(QLibraryInfo::TranslationsPath));
  app.installTranslator(&qtTranslator);

  QTranslator appTrans;
  appTrans.load(QStringLiteral(":/translations/gmp_") + QLocale::system().name());
  app.installTranslator(&appTrans);

  qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/qml/Player.qml")), "org.gmp.player", 1, 0, "Player");

  auto indexer = QScopedPointer<MusicIndexer>(new MusicIndexer);
  auto artistsModel = QScopedPointer<ArtistsModel>(new ArtistsModel(indexer.get()));
  auto albumsModel = QScopedPointer<AlbumsModel>(new AlbumsModel(indexer.get()));
  auto tracksModel = QScopedPointer<TracksModel>(new TracksModel(indexer.get()));
  auto genresModel = QScopedPointer<GenresModel>(new GenresModel(indexer.get()));

  QQmlApplicationEngine engine;

  qmlRegisterSingletonInstance("org.gmp.model", 1, 0, "MusicIndexer", indexer.get());
  qmlRegisterSingletonInstance("org.gmp.model", 1, 0, "ArtistsModel", artistsModel.get());
  qmlRegisterSingletonInstance("org.gmp.model", 1, 0, "AlbumsModel", albumsModel.get());
  qmlRegisterSingletonInstance("org.gmp.model", 1, 0, "TracksModel", tracksModel.get());
  qmlRegisterSingletonInstance("org.gmp.model", 1, 0, "GenresModel", genresModel.get());

  qmlRegisterType<GenericProxyModel>("org.gmp.model", 1, 0, "GenericProxyModel");
  qmlRegisterType<AlbumProxyModel>("org.gmp.model", 1, 0, "AlbumProxyModel");
  qmlRegisterType<DirectImage>("org.gmp.misc", 1, 0, "DirectImage");

  const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);
  engine.load(url);

  return app.exec();
}
