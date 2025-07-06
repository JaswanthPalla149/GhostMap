// ReadyFlagWriter.cpp
#include "ReadyFlagWriter.h"
#include <QFile>
#include <QTextStream>

ReadyFlagWriter::ReadyFlagWriter(QObject *parent) : QObject(parent) {}

void ReadyFlagWriter::writeFlag(const QString &filePath) {
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << "ready";
        file.close();
    }
}
