#ifndef FILE_DIALOG_HELPER_H
#define FILE_DIALOG_HELPER_H

#include <QObject>
#include <QStringList>

class FileDialogHelper : public QObject
{
    Q_OBJECT
public:
    explicit FileDialogHelper(QObject *parent = nullptr);

    Q_INVOKABLE QStringList openFiles(const QString &title,
                                      const QString &filter);
};

#endif
