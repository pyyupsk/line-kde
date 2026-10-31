#include "coreclient.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonValue>
#include <QProcessEnvironment>
#include <QStandardPaths>

namespace
{
    constexpr int AuthRequest = 1;
    constexpr int ChatsRequest = 2;
    constexpr int MessagesRequest = 3;
    constexpr int SendRequest = 4;
    constexpr int LogoutRequest = 5;
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
        restoreSession();
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        if (!m_sessionPath.isEmpty())
        {
            env.insert(QStringLiteral("LINE_KDE_SESSION"), m_sessionPath);
        }
        m_process.setProcessEnvironment(env);
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
    m_currentChat = mid;
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

void CoreClient::restartLogin()
{
    if (m_process.state() != QProcess::NotRunning)
    {
        m_process.kill();
        m_process.waitForFinished(2000);
    }
    m_qrSource.clear();
    m_pincode.clear();
    start();
}

void CoreClient::signOut()
{
    if (m_process.state() == QProcess::NotRunning)
    {
        return;
    }
    m_process.write(QByteArrayLiteral("{\"id\":5,\"method\":\"auth.logout\"}\n"));
}

void CoreClient::sendMessage(const QString &text)
{
    if (m_process.state() == QProcess::NotRunning || m_currentChat.isEmpty() || text.isEmpty())
    {
        return;
    }

    QJsonObject params;
    params.insert(QStringLiteral("mid"), m_currentChat);
    params.insert(QStringLiteral("text"), text);
    QJsonObject request;
    request.insert(QStringLiteral("id"), SendRequest);
    request.insert(QStringLiteral("method"), QStringLiteral("chat.send"));
    request.insert(QStringLiteral("params"), params);
    m_process.write(QJsonDocument(request).toJson(QJsonDocument::Compact) + '\n');
}

namespace
{
const QString WalletFolder = QStringLiteral("line-kde");
const QString WalletEntry = QStringLiteral("session");

QByteArray walletRead()
{
    QProcess query;
    query.start(QStringLiteral("kwallet-query"),
                {QStringLiteral("-f"), WalletFolder, QStringLiteral("-r"), WalletEntry, QStringLiteral("kdewallet")});
    if (!query.waitForFinished(5000))
    {
        return {};
    }
    return query.readAllStandardOutput().trimmed();
}

bool walletWrite(const QByteArray &blob)
{
    QProcess query;
    query.start(QStringLiteral("kwallet-query"),
                {QStringLiteral("-f"), WalletFolder, QStringLiteral("-w"), WalletEntry, QStringLiteral("kdewallet")});
    if (!query.waitForStarted(5000))
    {
        return false;
    }
    query.write(blob);
    query.closeWriteChannel();
    return query.waitForFinished(5000) && query.exitCode() == 0;
}
}

void CoreClient::restoreSession()
{
    m_sessionPath.clear();

    const QByteArray blob = walletRead();
    if (blob.isEmpty() || !blob.startsWith('{') || blob == "{}")
    {
        return;
    }

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + QStringLiteral("/line-kde");
    if (dir.isEmpty() || !QDir().mkpath(dir))
    {
        return;
    }
    m_sessionPath = dir + QStringLiteral("/session.json");

    QFile file(m_sessionPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
        file.write(blob);
    }
}

void CoreClient::persistSession()
{
    if (m_sessionPath.isEmpty())
    {
        return;
    }
    QFile file(m_sessionPath);
    if (!file.open(QIODevice::ReadOnly))
    {
        return;
    }
    walletWrite(file.readAll());
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
        ++m_qrSerial;
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

    if (message.value(QStringLiteral("method")).toString() == QStringLiteral("session.saved"))
    {
        persistSession();
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

    if (id == LogoutRequest)
    {
        walletWrite(QByteArrayLiteral("{}"));
        if (!m_sessionPath.isEmpty())
        {
            QFile::remove(m_sessionPath);
        }
        m_chats.clear();
        m_messages.clear();
        m_chatError.clear();
        m_currentChat.clear();
        m_userName.clear();
        Q_EMIT chatsChanged();
        Q_EMIT messagesChanged();
        setStatus(QStringLiteral("idle"));
        return;
    }

    if (id == SendRequest)
    {
        m_messages.append(message.value(QStringLiteral("result")).toObject().toVariantMap());
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
