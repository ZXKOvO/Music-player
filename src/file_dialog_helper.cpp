#include "file_dialog_helper.h"
#include <QFileDialog>

FileDialogHelper::FileDialogHelper(QObject *parent)
    : QObject(parent)
{}

QStringList FileDialogHelper::openFiles(const QString &title,
                                        const QString &filter)
{
    QFileDialog dlg(nullptr, title, QString(), filter);
    dlg.setFileMode(QFileDialog::ExistingFiles);
    dlg.setOption(QFileDialog::DontUseNativeDialog, true);
    if (dlg.exec() == QDialog::Accepted) {
        QStringList files;
        for (const auto &url : dlg.selectedUrls()) {
            files.append(url.toLocalFile());
        }
        return files;
    }
    return {};
}
