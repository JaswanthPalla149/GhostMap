#ifndef READYFLAGWRITER_H
#define READYFLAGWRITER_H

#include <QObject>

class ReadyFlagWriter : public QObject {
    Q_OBJECT

public:
    explicit ReadyFlagWriter(QObject* parent = nullptr);

    Q_INVOKABLE void setReady();
    Q_INVOKABLE void setUnready();

private:
    void writeFlag(const QString& flag);
};

#endif // READYFLAGWRITER_H
