#ifdef QT_NO_SYSTEMTRAYICON
#include <QGuiApplication>
#else
#include <QApplication>
#endif

#include <QQmlApplicationEngine>
#include <QTranslator>
#include <QLibraryInfo>
#include <QIcon>
#include <QQmlContext>
#include <QLoggingCategory>
#include <QTouchDevice>

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

    QLoggingCategory::setFilterRules("*.debug=true\nqt.*.debug=false");

    app.setOrganizationName(QStringLiteral("caybro"));
    app.setApplicationDisplayName(QStringLiteral("G Music Player"));
    app.setApplicationVersion(QStringLiteral("0.0.1"));

    app.setWindowIcon(QIcon(QStringLiteral(":/icons/ic_library_music_48px.svg")));

    QTranslator qtTranslator;
    qtTranslator.load(QLocale::system(), QStringLiteral("qt_"), QString(), QLibraryInfo::location(QLibraryInfo::TranslationsPath));
    app.installTranslator(&qtTranslator);

    QTranslator appTrans;
    appTrans.load(QStringLiteral(":/translations/gmp_") + QLocale::system().name());
    app.installTranslator(&appTrans);

    qmlRegisterSingletonType(QUrl("qrc:/qml/Player.qml"), "org.gmp.player", 1, 0, "Player");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
