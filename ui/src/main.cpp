/*
    SPDX-License-Identifier: GPL-2.0-or-later
    SPDX-FileCopyrightText: 2026 pyyupsk <>
*/

#include <QtGlobal>
#ifdef Q_OS_ANDROID
#include <QGuiApplication>
#else
#include <QApplication>
#endif

#include <QDir>
#include <QIcon>
#include <QLockFile>
#include <QStandardPaths>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>

#include "app.h"
#include "coreclient.h"
#include "version-linekde.h"
#include <KAboutData>
#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include "linekdeconfig.h"

using namespace Qt::Literals::StringLiterals;

#ifdef Q_OS_ANDROID
Q_DECL_EXPORT
#endif
int main(int argc, char *argv[])
{
#ifdef Q_OS_ANDROID
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle(QStringLiteral("org.kde.breeze"));
#else
    QApplication app(argc, argv);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
    {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }
#endif

#ifdef Q_OS_WINDOWS
    if (AttachConsole(ATTACH_PARENT_PROCESS))
    {
        freopen("CONOUT$", "w", stdout);
        freopen("CONOUT$", "w", stderr);
    }

    QApplication::setStyle(QStringLiteral("breeze"));
    auto font = app.font();
    font.setPointSize(10);
    app.setFont(font);
#endif

    const QString runtimeDir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    QDir().mkpath(runtimeDir + QStringLiteral("/line-kde"));
    QLockFile instanceLock(runtimeDir + QStringLiteral("/line-kde/linekde.lock"));
    instanceLock.setStaleLockTime(0);
    if (!instanceLock.tryLock(200))
    {
        qWarning("LINE for KDE is already running");
        return 0;
    }

    KLocalizedString::setApplicationDomain("linekde");
    QCoreApplication::setOrganizationName(u"KDE"_s);

    KAboutData aboutData(
        // The program name used internally.
        u"linekde"_s,
        // A displayable program name string.
        i18nc("@title", "LINE for KDE"),
        // The program version string.
        QStringLiteral(LINEKDE_VERSION_STRING),
        // Short description of what the app does.
        i18n("LINE client for KDE Plasma"),
        // The license this code is released under.
        KAboutLicense::GPL,
        // Copyright Statement.
        i18n("(c) 2026 pyyupsk"));
    aboutData.addAuthor(i18nc("@info:credit", "pyyupsk"), i18nc("@info:credit", "Maintainer"), u"contact@fasu.dev"_s);
    aboutData.setHomepage(u"https://github.com/pyyupsk/line-kde"_s);
    aboutData.setBugAddress(QByteArrayLiteral("https://github.com/pyyupsk/line-kde/issues"));
    aboutData.setDesktopFileName(u"com.pyyupsk.linekde"_s);
    aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    KAboutData::setApplicationData(aboutData);
    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"com.pyyupsk.linekde"_s));

    QQmlApplicationEngine engine;

    auto config = linekdeConfig::self();

    qmlRegisterSingletonInstance("com.pyyupsk.linekde.private", 1, 0, "Config", config);

    CoreClient core;
    engine.rootContext()->setContextProperty(u"Core"_s, &core);
    engine.rootContext()->setContextProperty(u"AppVersion"_s, QStringLiteral(LINEKDE_VERSION_STRING));

    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("com.pyyupsk.linekde", u"Main");

    if (engine.rootObjects().isEmpty())
    {
        return -1;
    }

    return app.exec();
}
