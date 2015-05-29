# TODO:
# DESKTOP_OPERATION_UI_DBUS_INFO=
#     DEST:
#     OBJECT_PATH:
#     INTERFACE:

get_path_basename = (uri)->
    uri.split('/').slice(-1).join('/')

get_path_dirname = (uri)->
    get_path_base(uri)

file_should_not_show = (basename) ->
    basename[0] == "." and not basename.match(/^.deepin_rich_dir_/) or basename.endsWith("~")


get_path_from_uri = (uri) ->
    try
        decodeURI(uri.match(/^\w+:\/\/(.*)/)[1])
    catch e
        console.error e
        ""


entry_is_app = (uri) ->
    uri.endsWith(".desktop")


DCore.DEntry.list_files = (entry)->
    entries = []
    try
        dir_url = DCore.DEntry.get_uri(entry)
        op = FileOperationFactory.NewListJob(dir_url, OperationFlags.ListJobFlagsIncludeHidden)
        files = op.execute()

        for info in files
            basename = info[1]
            file_uri = info[2]
            if file_should_not_show(basename)
                continue

            file_path = get_path_from_uri(file_uri)
            entries.push(DCore.DEntry.create_by_path(file_path))
    catch e
        console.error("list_files(#{dirURL}) error: #{e}")

    entries


DCore.DEntry.trash = (entry_list) ->
    entry_uris = entry_list.map((entry)->
        DCore.DEntry.get_uri(entry)
    )

    # TODO:
    # 1. read the settings for confirmation
    # 2. UI.
    shouldConfirm = false
    op = FileOperationFactory.NewTrashJob(entry_uris, shouldConfirm, "", "", "")
    op.execute_async()


DCore.DEntry.confirm_trash = ->
    # TODO:
    # 1. read the settings for confirmation
    # 2. UI
    shouldConfirm = true
    op = FileOperationFactory.NewEmptyTrashJob(shouldConfirm, "com.deepin.dde.desktop", "/com/deepin/dde/desktop", "com.deepin.dde.desktop")
    op.execute_async()


DCore.DEntry.get_trash_count = ->
    trash_monitor = DCore.DBus.session_object("com.deepin.filemanager.Backend.Monitor", "/com/deepin/filemanager/Backend/Monitor", "com.deepin.filemanager.Backend.TrashMonitor")
    DCore.DEntry.get_trash_count = ->
        trash_monitor.ItemCount_sync()
    DCore.DEntry.get_trash_count()


DCore.DEntry.get_templates_files = ->
    op = FileOperationFactory.NewGetTemplateJob()
    op.execute().map((uri)->
        file_path = get_path_from_uri(uri)
        DCore.DEntry.create_by_path(file_path)
    )

DCore.DEntry.is_native = (entry)->
    uri = DCore.DEntry.get_uri(entry)
    FileInfo.IsNativeFile_sync(uri)

DCore.DEntry.get_mtime = (entry)->
    uri = DCore.DEntry.get_uri(entry)
    mtime_attribute = FileInfo.FileAttributeTimeModified
    info = query_file_info(uri, mtime_attribute, FileInfo.QueryFlagNofollowSymlinks)
    return 0 if info == ""
    mtime = JSON.parse(info)[mtime_attribute]
    mtime

FILE_TYPE_APP = 0
FILE_TYPE_FILE = 1
FILE_TYPE_DIR = 2
FILE_TYPE_RICH_DIR = 3
FILE_TYPE_INVALID_LINK = 4
FILE_TYPE_NOT_SUPPORT = 5

is_deepin_rich_dir = (path) ->
    path.startsWith(".deepin_rich_dir_")

get_file_type = (uri)->
    return FILE_TYPE_APP if entry_is_app(uri)

    type_attribute = FileInfo.FileAttributeStandardType
    info = query_file_info(uri, type_attribute, FileInfo.QueryFlagNofollowSymlinks)
    return FILE_TYPE_NOT_SUPPORT if info == ""
    file_type = JSON.parse(info)[type_attribute]
    switch file_type
        when FileInfo.FileTypeRegular
            return FILE_TYPE_FILE
        when FileInfo.FileTypeDirectory
            name = get_path_basename(decodeURI(uri))
            if is_deepin_rich_dir(name)
                return FILE_TYPE_RICH_DIR
            return FILE_TYPE_DIR
        when FileInfo.FileTypeSymbolicLink
            link_target_attribute FileInfo.FileAttributeStandardSymlinkTarget
            info = query_file_info(uri, link_target_attribute, FileInfo.QueryFlagNofollowSymlinks)
            return FILE_TYPE_INVALID_LINK if info == ""

            target = JSON.parse(info)[link_target_attribute]
            return get_file_type(target)
        else
            return FILE_TYPE_NOT_SUPPORT

DCore.DEntry.get_type = (entry) ->
    uri = DCore.DEntry.get_uri(entry)
    get_file_type(uri)


DCore.DEntry.get_flags = (entry)->
    uri = DCore.DEntry.get_uri(entry)
    is_symlink_attr = FileInfo.FileAttributeStandardIsSymlink
    can_read_attr = FileInfo.FileAttributeAccessCanRead
    can_write_attr = FileInfo.FileAttributeAccessCanWrite
    info = query_file_info(uri, "#{is_symlink_attr},#{can_read_attr},#{can_write_attr}", FileInfo.QueryFlagNofollowSymlinks)
    if info == ""
        return {}
    read_only: not info[can_write_attr]
    symbolic_link: info[is_symlink_attr]
    unreadable: not info[can_read_attr]

# TODO:
# DCore.DEntry.get_icon = (entry)->

DCore.DEntry.create_templates = (entry)->
    uri = DCore.DEntry.get_uri(entry)
    # TODO: UI
    op = FileOperationFactory.NewCreateFileFromTemplateJob(DCore.Desktop.get_desktop_path(), uri, "", "" ,"")
    op.connect("Done", (errMsg)->
        if errMsg != ""
            console.log("create_templates failed: #{errMsg}")
            return
        entry = DCore.DEntry.create_by_path(DCore.Desktop.get_desktop_path() + "/" + get_path_name(uri))
        create_entry_to_new_item(entry)
    )
    op.execute_async()


DCore.DEntry.set_name = (entry, new_name)->
    uri = DCore.DEntry.get_uri(entry)
    op = FileOperationFactory.NewRenameJob(uri, new_name)
    op.connect("Done", (errMsg)->
        if errMsg != ""
            DCore.DEntry.show_rename_error_dialog(new_name, entry_is_app(uri))
    )
    op.execute_async()

DCore.DEntry.delete_files = (entry_list, shouldConfirm)->
    uris = entry_list.map((entry)->
        DCore.DEntry.get_uri(entry)
    )
    # TODO: UI
    op = FileOperationFactory.NewDeleteJob(uris, shouldConfirm, "", "", "")
    op.execute_async()


DCore.DEntry.move = (entry_list, destDir, prompt) ->
    srcs = entry_list.map((e)->DCore.DEntry.get_uri(e))
    # TODO: UI
    dest = ""
    objPath = ""
    iface = ""
    if not prompt
        dest = ""
        objPath = ""
        iface = ""
    op = FileOperationFactory.NewMoveJob(srcs, DCore.DEntry.get_uri(destDir), "", 0, dest, objPath, iface)
    op.execute_async()


DCore.DEntry.copy = (entry_list, destDir)->
    srcs = entry_list.map((e)->DCore.DEntry.get_uri(e))
    # TODO: UI
    op = FileOperationFactory.NewCopyJob(srcs, DCore.DEntry.get_uri(destDir), "", 0, "", "", "")
    op.connect("Done", (w)->
        console.log(w)
    )
    op.execute_async()
