#pragma once

#include <QByteArray>
#include <QJsonObject>
#include <QObject>
#include <QProcess>
#include <QString>

class CoreClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(QString qrSource READ qrSource NOTIFY changed)
    Q_PROPERTY(QString pincode READ pincode NOTIFY changed)
    Q_PROPERTY(QString userName READ userName NOTIFY changed)
    Q_PROPERTY(QString errorText READ errorText NOTIFY changed)

public:
    explicit CoreClient(QObject *parent = nullptr);

    QString status() const { return m_status; }
    QString qrSource() const { return m_qrSource; }
    QString pincode() const { return m_pincode; }
    QString userName() const { return m_userName; }
    QString errorText() const { return m_error; }

    Q_INVOKABLE void start();

Q_SIGNALS:
    void changed();

private:
    void readOutput();
    void handle(const QJsonObject &message);
    void setStatus(const QString &status);
    void fail(const QString &message);

    QProcess m_process;
    QByteArray m_buffer;
    QString m_status = QStringLiteral("idle");
    QString m_qrSource;
    QString m_pincode;
    QString m_userName;
    QString m_error;
};
