#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QtPlugin>
#include "TcpServer.h"
#include "ReadyFlagWriter.h"
#include <QtQml/qqmlextensionplugin.h>

// This line is crucial - it registers your QmlComponents module
//Q_IMPORT_QML_PLUGIN(QmlComponentsModulePlugin)
//Q_IMPORT_PLUGIN(QmlComponentsModulePlugin)
int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/qml");
    TcpServer server;
    ReadyFlagWriter flagWriter;
    engine.rootContext()->setContextProperty("tcpServer", &server);
    qDebug() << "GPS TCP Server running on port 12345";
    //engine.load(QUrl(QStringLiteral("qrc:/qml/GPSViewer/qml/Main.qml")));
    //engine.addImportPath("qrc:/qml");
    engine.rootContext()->setContextProperty("FlagWriter", &flagWriter);
    const QUrl url(QStringLiteral("qrc:/qml/GPSViewer/qml/Main.qml"));
    
    //const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qDebug() << "Failed to load QML at" << url;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}