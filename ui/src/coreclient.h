#pragma once

#include <QByteArray>
#include <QJsonObject>
#include <QObject>
#include <QProcess>
#include <QString>

#include <QVariantList>

class CoreClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(QString qrSource READ qrSource NOTIFY changed)
    Q_PROPERTY(QString pincode READ pincode NOTIFY changed)
    Q_PROPERTY(QString userName READ userName NOTIFY changed)
    Q_PROPERTY(QString errorText READ errorText NOTIFY changed)
    Q_PROPERTY(QVariantList chats READ chats NOTIFY chatsChanged)
    Q_PROPERTY(QVariantList messages READ messages NOTIFY messagesChanged)
    Q_PROPERTY(QString chatError READ chatError NOTIFY messagesChanged)
    Q_PROPERTY(int qrSerial READ qrSerial NOTIFY changed)

public:
    explicit CoreClient(QObject *parent = nullptr);

    QString status() const { return m_status; }
    QString qrSource() const { return m_qrSource; }
    QString pincode() const { return m_pincode; }
    QString userName() const { return m_userName; }
    QString errorText() const { return m_error; }
    QVariantList chats() const { return m_chats; }
    QVariantList messages() const { return m_messages; }
    QString chatError() const { return m_chatError; }
    int qrSerial() const { return m_qrSerial; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void listChats();
    Q_INVOKABLE void openChat(const QString &mid);
    Q_INVOKABLE void sendMessage(const QString &text);
    Q_INVOKABLE void signOut();
    Q_INVOKABLE void restartLogin();

Q_SIGNALS:
    void changed();
    void chatsChanged();
    void messagesChanged();

private:
    void readOutput();
    void restoreSession();
    void persistSession();
    void handle(const QJsonObject &message);
    void setStatus(const QString &status);
    void fail(const QString &message);

    QProcess m_process;
    QByteArray m_buffer;
    QVariantList m_chats;
    QVariantList m_messages;
    QString m_chatError;
    int m_qrSerial = 0;
    QByteArray m_lastSaved;
    QString m_sessionPath;
    QString m_currentChat;
    QString m_status = QStringLiteral("idle");
    QString m_qrSource;
    QString m_pincode;
    QString m_userName;
    QString m_error;
};
