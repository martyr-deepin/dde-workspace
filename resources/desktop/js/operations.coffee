FILE_OPERATION_DBUS_INFO =
    DEST: "com.deepin.filemanager.Backend.Operations"
    OBJECT_PATH: "/com/deepin/filemanager/Backend/Operations"
    INTERFACE: "com.deepin.filemanager.Backend.Operations"


OperationFlags = DCore.DBus.session_object(
    FILE_OPERATION_DBUS_INFO.DEST,
    FILE_OPERATION_DBUS_INFO.OBJECT_PATH,
    FILE_OPERATION_DBUS_INFO.INTERFACE + ".Flags"
)

FileInfo = DCore.DBus.session_object(
    FILE_OPERATION_DBUS_INFO.DEST,
    FILE_OPERATION_DBUS_INFO.OBJECT_PATH + "/FileInfo",
    FILE_OPERATION_DBUS_INFO.INTERFACE + ".FileInfo"
)

query_file_info = (args...)->
    FileInfo.QueryInfo_sync(args...)

class FileOperation
    constructor: (@op)->
        for p in Object.keys(@op)
            @[p] = (args...)->
                @op["#{p}"].apply(@op, args)

    connect: (signal, handler)->
        @op.connect(signal, handler)

    execute:->
        @op.Execute_sync()

    execute_async: ->
        @op.Execute()


class FileOperationsManager
    constructor: ->
        @dbus = DCore.DBus.session(FILE_OPERATION_DBUS_INFO.DEST)
        for name in Object.keys(@dbus)
            if not name.match(/_sync$/)
                @createMethod(name)

    createMethod:(name)->
        @[name] = (args...) ->
            [objPath, iface] = @dbus["#{name}_sync"].apply(@dbus, args)
            if iface == ""
                return null
            new FileOperation(DCore.DBus.session_object(FILE_OPERATION_DBUS_INFO.DEST, objPath, iface))


FileOperationFactory = new FileOperationsManager()
