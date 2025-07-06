// ReadyFlagWriter.h
#ifndef READYFLAGWRITER_H
#define READYFLAGWRITER_H

#include <QObject>

class ReadyFlagWriter : public QObject {
    Q_OBJECT
public:
    explicit ReadyFlagWriter(QObject *parent = nullptr);

    Q_INVOKABLE void writeFlag(const QString &filePath);
};

#endif // READYFLAGWRITER_H
