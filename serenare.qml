import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.4

ApplicationWindow {
    title: qsTr("Serenare 0.4-dev")
    width: 840
    height: 480
    visible: true

    function send(message) {
        python.call('serenare.serenClient.write', [message]);
    }

    function sendUserInput() {
        var widget = textInput;
        send(widget.text);
        widget.text = "";
    }

    function generic(part) {
        return '<span style="color: midnightblue;">'+
               part+'</span>';
    }

    toolBar: ToolBar {
        RowLayout {
            anchors.fill: parent
            Item {
                Layout.fillWidth: true
            }
            Switch {
                id: autoacceptStatus
                checked: false
                property bool status: false
                onStatusChanged: {
                    checked = status;
                }
                onCheckedChanged: {
                    if (status != checked) {
                        send('autoaccept '+(checked && '1' || '0'));
                    }
                }
            }
            Label {
                text: qsTr("Autoaccept")
            }
            /*
            Item {
                Layout.fillWidth: true
            }
            Switch {
                id: recStatus
                checked: false
                property bool status: false
                onStatusChanged: {
                    checked = status;
                }
                onCheckedChanged: {
                    if (status != checked) {
                        send('/r');
                    }
                }
            }
            Label {
                text: qsTr("Recording")
            }
            */
            Item {
                Layout.fillWidth: true
            }
            Switch {
                id: loopbackStatus
                checked: false
                property bool status: false
                onStatusChanged: {
                    checked = status;
                }
                onCheckedChanged: {
                    if (status != checked) {
                        send('loop '+(checked && '1' || '0'));
                    }
                }
            }
            Label {
                text: qsTr("Loopback")
            }
            Item {
                Layout.fillWidth: true
            }
            Switch {
                id: micStatus
                checked: true
                property bool status: false
                onStatusChanged: {
                    checked != status;
                }
                onCheckedChanged: {
                    if (status == checked) {
                        send('mute '+(checked && '0' || '1'));
                    }
                }
            }
            Label {
                text: qsTr("Microphone")
            }
            Item {
                Layout.fillWidth: true
            }
        }
    }

    ListModel {
        id: userListModel
    }

    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            TextArea {
                id: messageBox
                readOnly: true
                textFormat: TextEdit.RichText
                Layout.fillWidth: true
                Layout.fillHeight: true
                onLinkActivated: Qt.openUrlExternally(link)
            }
            TableView {
                id: userListView
                model: userListModel
                TableViewColumn {
                    role: 'username'
                    title: qsTr("Users")
                }
                Layout.fillHeight: true
            }
        }
        RowLayout {
            TextField {
                id: textInput
                Layout.fillWidth: true
                focus: true
                Keys.onReturnPressed: sendUserInput()
            }
            Button {
                text: "Send"
                onClicked: sendUserInput()
            }
        }
    }

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));
            importModule('serenare', function () {
                call('serenare.start_seren');
            });
        }
        onError: {
            console.log("Error: " + traceback);
            Qt.quit();
        }
        onReceived: {
            switch (data[0]) {
                case 'generic':
                    messageBox.append(generic(data[1]));
                    break;
                case 'message':
                    messageBox.append('<span style="color: blue;">'+
                                      data[2]+'</span> '+data[3]);
                    break;
                case 'node-join':
                    userListModel.append({'username':data[2], 'host':data[3]});
                    break;
                case 'node-left':
                    for (var i=0; i<userListModel.count; i++) {
                        if (userListModel.get(i)['host'] === data[3]) {
                            userListModel.remove(i);
                            break;
                        }
                    }
                    break;
                case 'autoaccept':
                    autoacceptStatus.status = data[1];
                    break
                case 'mute':
                    micStatus.status = data[1];
                    break;
                case 'recording':
                    recStatus.status = data[1];
                    break;
                case 'loop':
                    loopbackStatus.status = data[1];
                    break;
                case 'exit':
                    Qt.quit();
                    break;
            }
            console.log(data);
        }
    }
}
