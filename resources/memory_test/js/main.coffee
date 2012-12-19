run = (f)->
    setInterval(f, 1)

file_test = ->
    a = DCore.DFile.create_by_path("/dev/shm/123")
    echo DCore.DFile.get_basename(a)
    echo DCore.DFile.get_id(a)


#run(file_test)


list_test = (path)->
    #path = "/usr/bin"
    path = "/usr/share"
    a = DCore.DFile.create_by_path(path)
    fs = DCore.DFile.list_files(a)
    for f in fs
        DCore.DFile.get_id(f)

run(list_test)
