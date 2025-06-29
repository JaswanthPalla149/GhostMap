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
        qDebug() << "✅ GPS TCP Server running on port 12345";
    }
}

void TcpServer::onNewConnection() {
    QTcpSocket *socket = server->nextPendingConnection();
    qDebug() << "🔌 New TCP connection established from" << socket->peerAddress().toString();

    connect(socket, &QTcpSocket::readyRead, [=]() {
        QByteArray data = socket->readAll();
        qDebug() << "📩 Received raw data:" << data;

        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
        if (parseError.error != QJsonParseError::NoError) {
            qWarning() << "❌ JSON parse error:" << parseError.errorString();
            return;
        }

        QVariantList list;
        QJsonArray arr;

        // Either accept direct array or nested JSON
        if (doc.isObject()) {
            arr = doc.object().value("detections").toArray();
        } else if (doc.isArray()) {
            arr = doc.array();
        }

        for (const auto &val : arr) {
            QJsonObject obj = val.toObject();
            QVariantMap m;
            m["class_id"] = obj["class_id"].toString();
            m["lat"] = obj["latitude"].toDouble();
            m["lon"] = obj["longitude"].toDouble();
            list.append(m);
            qDebug() << "📍 Parsed GPS:" << m;
        }

        emit gpsUpdated(list);
        qDebug() << "📤 Emitted gpsUpdated signal with" << list.size() << "items.";
    });

    connect(socket, &QTcpSocket::disconnected, socket, &QTcpSocket::deleteLater);
}
