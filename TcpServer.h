// TcpServer.h
#pragma once
#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QVariantList>

class TcpServer : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList gpsList READ gpsList NOTIFY gpsListChanged) // Changed signal name

public:
    explicit TcpServer(QObject *parent = nullptr);
    QVariantList gpsList() const { return m_gpsList; }

signals:
    void gpsListChanged(); // New signal for property change

private slots:
    void onNewConnection();

private:
    QTcpServer *server;
    QVariantList m_gpsList;
};
