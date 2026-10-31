#include "coreclient.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonValue>

namespace
{
    constexpr int AuthRequest = 1;
    constexpr int ChatsRequest = 2;
    constexpr int MessagesRequest = 3;
}

CoreClient::CoreClient(QObject *parent)
    : QObject(parent)
{
    connect(&m_process, &QProcess::readyReadStandardOutput, this, &CoreClient::readOutput);
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError)
            { fail(m_process.errorString()); });
    connect(&m_process, &QProcess::finished, this, [this](int code, QProcess::ExitStatus)
            {
        if (code != 0) {
            fail(QStringLiteral("core exited with code %1").arg(code));
        } });
}

void CoreClient::start()
{
    if (m_process.state() == QProcess::NotRunning)
    {
        m_error.clear();
        m_qrSource.clear();
        m_pincode.clear();
        setStatus(QStringLiteral("starting"));
        m_process.start(QStringLiteral("node"), {QStringLiteral(LINE_KDE_CORE)});
    }
    if (!m_process.waitForStarted(5000))
    {
        fail(m_process.errorString());
        return;
    }
    m_process.write(QByteArrayLiteral("{\"id\":1,\"method\":\"auth.start\"}\n"));
}

void CoreClient::listChats()
{
    if (m_process.state() == QProcess::NotRunning)
    {
        return;
    }
    m_process.write(QByteArrayLiteral("{\"id\":2,\"method\":\"chats.list\"}\n"));
}

void CoreClient::openChat(const QString &mid)
{
    if (m_process.state() == QProcess::NotRunning)
    {
        return;
    }
    m_messages.clear();
    m_chatError.clear();
    Q_EMIT messagesChanged();

    QJsonObject params;
    params.insert(QStringLiteral("mid"), mid);
    QJsonObject request;
    request.insert(QStringLiteral("id"), MessagesRequest);
    request.insert(QStringLiteral("method"), QStringLiteral("chat.messages"));
    request.insert(QStringLiteral("params"), params);
    m_process.write(QJsonDocument(request).toJson(QJsonDocument::Compact) + '\n');
}

void CoreClient::readOutput()
{
    m_buffer += m_process.readAllStandardOutput();
    int newline;
    while ((newline = m_buffer.indexOf('\n')) >= 0)
    {
        const QByteArray line = m_buffer.left(newline).trimmed();
        m_buffer.remove(0, newline + 1);
        if (line.isEmpty())
        {
            continue;
        }
        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(line, &error);
        if (error.error != QJsonParseError::NoError)
        {
            fail(error.errorString());
            continue;
        }
        handle(document.object());
    }
}

void CoreClient::handle(const QJsonObject &message)
{
    const QJsonObject params = message.value(QStringLiteral("params")).toObject();

    const QJsonValue qr = params.value(QStringLiteral("png"));
    if (qr.isString())
    {
        m_qrSource = QStringLiteral("data:image/png;base64,") + qr.toString();
        setStatus(QStringLiteral("waiting"));
        return;
    }

    const QJsonValue pin = params.value(QStringLiteral("pin"));
    if (pin.isString())
    {
        m_pincode = pin.toString();
        Q_EMIT changed();
        return;
    }

    if (!message.contains(QStringLiteral("id")))
    {
        return;
    }

    const QJsonObject error = message.value(QStringLiteral("error")).toObject();
    const int id = message.value(QStringLiteral("id")).toInt();
    if (!error.isEmpty())
    {
        if (id == MessagesRequest)
        {
            m_chatError = error.value(QStringLiteral("message")).toString();
            Q_EMIT messagesChanged();
            return;
        }
        fail(error.value(QStringLiteral("message")).toString());
        return;
    }

    if (id == MessagesRequest)
    {
        m_messages.clear();
        const QJsonArray messages = message.value(QStringLiteral("result")).toArray();
        for (const QJsonValue &entry : messages)
        {
            m_messages.append(entry.toObject().toVariantMap());
        }
        Q_EMIT messagesChanged();
        return;
    }

    if (id == ChatsRequest)
    {
        m_chats.clear();
        const QJsonArray chats = message.value(QStringLiteral("result")).toArray();
        for (const QJsonValue &chat : chats)
        {
            m_chats.append(chat.toObject().toVariantMap());
        }
        Q_EMIT chatsChanged();
        return;
    }

    m_userName = message.value(QStringLiteral("result")).toObject().value(QStringLiteral("name")).toString();
    setStatus(QStringLiteral("signedIn"));
    listChats();
}

void CoreClient::setStatus(const QString &status)
{
    m_status = status;
    Q_EMIT changed();
}

void CoreClient::fail(const QString &message)
{
    m_error = message;
    setStatus(QStringLiteral("error"));
}
