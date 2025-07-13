#include "TcpServer.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

TcpServer::TcpServer(QObject *parent) : QObject(parent) {
    server = new QTcpServer(this);
    connect(server, &QTcpServer::newConnection, this, &TcpServer::onNewConnection);
    if (!server->listen(QHostAddress::Any, 12345)) {
        qWarning() << "❌ Failed to start server:" << server->errorString();
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

        QList<QByteArray> packets = data.split('\n');  // Split by newline
        QVariantList latestValidList;

        for (const QByteArray &packet : packets) {
            if (packet.trimmed().isEmpty())
                continue;

            QJsonParseError parseError;
            QJsonDocument doc = QJsonDocument::fromJson(packet, &parseError);

            if (parseError.error == QJsonParseError::NoError) {
                QJsonArray arr;
                if (doc.isObject()) {
                    arr = doc.object().value("detections").toArray(); // if "detections" wrapped
                } else if (doc.isArray()) {
                    arr = doc.array(); // raw array
                }

                QVariantList list;
                for (const QJsonValue &val : arr) {
                    QJsonObject obj = val.toObject();
                    QVariantMap m;
                    m["class_id"] = obj["class_id"].toString();
                    m["lat"] = obj["lat"].toDouble();
                    m["lon"] = obj["lon"].toDouble();
                    list.append(m);
                    qDebug() << "📍 Parsed GPS:" << m;
                }

                // Save this one — it's the most recent valid array
                latestValidList = list;
            } else {
                qWarning() << "❌ JSON parse error:" << parseError.errorString();
            }
        }

        // Update UI only if we got something valid
        if (!latestValidList.isEmpty()) {
            m_gpsList = latestValidList;
            emit gpsListChanged();
            qDebug() << "📤 Updated gpsList with" << latestValidList.size() << "items.";
        }
    });


    connect(socket, &QTcpSocket::disconnected, socket, &QTcpSocket::deleteLater);
}
