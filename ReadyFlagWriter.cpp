#include "ReadyFlagWriter.h"
#include <QFile>
#include <QTextStream>
#include <iostream>
ReadyFlagWriter::ReadyFlagWriter(QObject* parent)
    : QObject(parent)
{}

void ReadyFlagWriter::writeFlag(const QString& flag) {
    QFile file("gps_ready.flag");

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        std::cerr << "[ERROR] Failed to open gps_ready.flag for writing: "
                  << file.errorString().toStdString() << std::endl;
        return;
    }

    QTextStream out(&file);
    out << flag;
    file.close();

    std::cout << "[DEBUG] Flag written: " << flag.toStdString() << std::endl;
}


void ReadyFlagWriter::setReady() {
    writeFlag("ready");
}

void ReadyFlagWriter::setUnready() {
    std::cout<<"Hi in Unready"<<std::endl;
    writeFlag("No");
}
