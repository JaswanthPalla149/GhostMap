#pragma once
#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QVariantList>

class TcpServer : public QObject {
    Q_OBJECT
public:
    explicit TcpServer(QObject *parent = nullptr);

signals:
    void gpsUpdated(QVariantList gpsList);

private slots:
    void onNewConnection();

private:
    QTcpServer *server;
};