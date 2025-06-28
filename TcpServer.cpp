#include "TcpServer.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

TcpServer::TcpServer(QObject *parent) : QObject(parent) {
    server = new QTcpServer(this);
    connect(server, &QTcpServer::newConnection, this, &TcpServer::onNewConnection);
    if (!server->listen(QHostAddress::Any, 12345)) {
        qWarning() << "Failed to start server:" << server->errorString();
    } else {
        qDebug() << "GPS TCP Server running on port 12345";
    }
}

void TcpServer::onNewConnection() {
    QTcpSocket *socket = server->nextPendingConnection();
    connect(socket, &QTcpSocket::readyRead, [=]() {
        QByteArray data = socket->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QVariantList list;
        for (const auto &val : doc.array()) {
            QJsonObject obj = val.toObject();
            QVariantMap m;
            m["class_id"] = obj["class_id"].toString();
            m["lat"] = obj["lat"].toDouble();
            m["lon"] = obj["lon"].toDouble();
            list.append(m);
        }
        emit gpsUpdated(list);
        socket->disconnectFromHost();
    });
}