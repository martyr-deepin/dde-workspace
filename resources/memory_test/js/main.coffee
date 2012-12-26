run = (f, times)->
    if times
        f()
    else
        setInterval(f, 1)

file_test = ->
    a = DCore.DEntry.create_by_path("/dev/shm/123")
    echo DCore.DEntry.get_basename(a)
    echo DCore.DEntry.get_id(a)




list_test = (path)->
    #path = "/usr/bin"
    path = "/usr/share"
    a = DCore.DEntry.create_by_path(path)

    DCore.DEntry.asdf

    DCore.DEntry.get_launchable()

    DCore.DEntry.get_id()
    DCore.DApp.get_id()

    fs = DCore.DEntry.list_files(a)
    for f in fs
        DCore.DEntry.get_id(f)

icon_test = ->
    a = DCore.DEntry.create_by_path("/")
    echo DCore.DEntry.get_icon(a)
    echo DCore.DEntry.get_id(a)
    echo DCore.DEntry.get_path(a)
    echo DCore.DEntry.get_name(a)

#run(file_test)
#run(list_test)
run(icon_test, 1)
