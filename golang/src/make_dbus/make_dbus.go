package make_dbus
import (
    "fmt"
    "os"
    "strings"
    "text/template"
    "flag"
    "path/filepath"
)
var output_c *os.File = os.Stdout
var output_h *os.File = os.Stdout

type CallbackStruct struct {
    Name string
}

const (
    InvalidArg = ""
    InArg = "in"
    OutArg = "out"
)
var type_table = map[string]string {
    "char*": "s",
    "gchar*": "s",
    "char": "y",
    "gchar": "y",
    "gboolean": "b",
    "gint16": "n",
    "guint16": "q",
    "gint32": "u",
    "gint64": "x",
    "guint64": "t",
    "gdouble": "d",
}

type ArgStruct struct {
    Name string
    CName string
    DName string
    Type string
}
func checkArgValid(value []string) {
    if len(value) != 2 {
        panic(fmt.Sprintf("Ret string is not valid: %q", strings.Join(value, ":")))
    }
    if type_table[value[1]] == "" {
        panic(fmt.Sprintf("Can't convert the Ctype(%s) to DBUS type", value[1]))
    }
}
func Ret(input string) ArgStruct {
    value := strings.Split(input, ":")
    checkArgValid(value)
    return ArgStruct{value[0], value[1], type_table[value[1]], OutArg}
}
func Arg(input string) ArgStruct {
    value := strings.Split(input, ":")
    checkArgValid(value)
    return ArgStruct{value[0], value[1], type_table[value[1]], InArg}
}


type MethodStruct struct {
    BusInfo *BusInfoStruct
    Ret ArgStruct
    Name string
    CB CallbackStruct
    Args []ArgStruct
}
func Method(name string, cb CallbackStruct, args...ArgStruct) MethodStruct {
    if len(args) > 0 && args[0].Type == OutArg {
        return MethodStruct{nil, args[0], name, cb, args[1:]}
    }
    ret := ArgStruct{"", "void", "", InvalidArg}
    return MethodStruct{nil, ret, name, cb, args}
}
func (m MethodStruct) joinArgs(prefix...string) string{
    ret := make([]string, len(m.Args))
    for i, arg := range m.Args {
        pre := ""
        if len(prefix) == 1 {
            pre = prefix[0]
        }
        ret[i] = pre + arg.CName
    }
    return strings.Join(ret, ",")
}
func Callback(name string) CallbackStruct {
    return CallbackStruct{name}
}

var temp_provider = template.Must(template.New("dbus_xml").Funcs(template.FuncMap{
    "gen_arg_call": func(name string, args []ArgStruct) string {
        ret := make([]string, len(args))
        for i, _ := range args {
            ret[i] = fmt.Sprintf("arg%d", i)
        }
        var get_variant string
        if len(args) != 0 {
            ret2 := make([]string, len(args))
            signals := make([]string, len(args))
            for i, s := range args {
                ret2[i] = fmt.Sprintf("&arg%d", i)
                signals[i] = s.DName
            }
            get_variant = fmt.Sprintf("g_variant_get(params, \"(%s)\", %s);\n", strings.Join(signals, ""), strings.Join(ret2, ", "))
        }

        return fmt.Sprintf("    %s            %s(%s);",
            get_variant,
            name,
            strings.Join(ret, ", "),
        )
    },
    "func_decl": func(method MethodStruct) string {
        return fmt.Sprintf("%s %s(%s);", method.Ret.CName, method.CB.Name, method.joinArgs())
    },
}).Parse(`
static int _service_owner_id = 0;
static GDBusInterfaceInfo * interface_info = NULL;
{{range .Methods}}
{{func_decl .}}
{{end}}
static void _bus_method_call (GDBusConnection * connection,
                 const gchar * sender, const gchar * object_path, const gchar * interface,
                 const gchar * method, GVariant * params,
                 GDBusMethodInvocation * invocation, gpointer user_data)
{
        GVariant * retval = NULL;
        if (0) { {{range .Methods}}
        } else if (g_strcmp0(method, "{{.Name}}") == 0) {
    {{range $index, $arg := .Args}}
        {{$arg.CName}} arg{{$index}};
    {{end}}
    {{if .Ret.Type }} {{..Ret.CName}} _c_retval = {{end}}
    {{gen_arg_call .CB.Name .Args}}

    {{if .Ret.Type }}
        retval = g_variant_new("({{..Ret.DName}})", _c_retval);
    {{end}}
        g_dbus_method_invocation_return_value (invocation, retval);
        return;
    {{end}}
    } else {
        g_dbus_method_invocation_return_dbus_error (invocation,
                "{{.BusInfo.Name}}.Error",
                "Can't find this method");
        return;
    }

}
static void _on_bus_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data)
{
    static GDBusInterfaceVTable interface_table = {
        method_call:   _bus_method_call,
        get_property:   NULL, /* No properties */
        set_property:   NULL  /* No properties */
    };
    GError* error = NULL;
    g_dbus_connection_register_object (connection,
            "{{.BusInfo.Path}}",
            interface_info,
            &interface_table,
            user_data,
            NULL,
            &error);

    if (error != NULL) {
        g_critical ("Unable to register the object to DBus: %s", error->message);
        g_error_free (error);
        g_bus_unown_name (_service_owner_id);
    }
}

void
{{.Setup_func_name}}()
{
    const char* xml = "<?xml version=\"1.0\"?>"
"<node>"
"<interface name=\"{{.BusInfo.Ifce}}\">"
{{range .Methods}}"       <method name=\"{{.Name}}\">"
{{if .Ret.Type}}"             <arg name=\"{{..Ret.Name}}\" type=\"{{..Ret.DName}}\" direction=\"out\"></arg>"
{{end}}{{range .Args}}"             <arg name=\"{{.Name}}\" type=\"{{.DName}}\" direction=\"{{.Type}}\"></arg>"
{{end}}"       </method>"
{{end}}"</interface>"
"</node>";

    GError* error = NULL;
    GDBusNodeInfo * node_info = g_dbus_node_info_new_for_xml (xml, &error);
    if (error != NULL) {
        g_critical ("Unable to parse interface xml: %s", error->message);
        g_error_free (error);
    }

    interface_info = g_dbus_node_info_lookup_interface (node_info, "{{.BusInfo.Ifce}}");
    /*g_dbus_node_info_unref(node_info);*/
    if (interface_info == NULL) {
        g_critical ("Unable to find interface \"{{.BusInfo.Ifce}}\"");
    }

    _service_owner_id = g_bus_own_name ({{.BusInfo.Type}},
            "{{.BusInfo.Name}}",
            G_BUS_NAME_OWNER_FLAGS_NONE,
            _on_bus_acquired,
            NULL,
            NULL,
            NULL,
            NULL);
}
`))


type InputInfo struct {
    Setup_func_name string
    BusInfo BusInfoStruct
    Methods []MethodStruct
}

type BusInfoStruct struct {
    Type string
    Name string
    Path string
    Ifce string
    Flags int
}

func to_path(info string) string {
    return strings.Replace("/" + info, ".", "/", -1)
}

func SessionDBUS(info string) BusInfoStruct {
    return BusInfoStruct{"G_BUS_TYPE_SESSION", info, to_path(info), info, FLAGS_NONE}
}

func DBusInstall(setup_func_name string, bus BusInfoStruct, methods...MethodStruct) {
    for i, _ := range methods {
        methods[i].BusInfo =&bus
    }
    output_h.WriteString(fmt.Sprintf("void %s();\n", setup_func_name))
    err := temp_provider.Execute(output_c, InputInfo{
        setup_func_name,
        bus,
        methods})
    if err != nil {
        panic(err)
    }
}

func temp_caller_func_decl (m MethodStruct) string {
    var decl string
    for i, arg := range m.Args {
        if arg.Type == InArg {
            decl += fmt.Sprintf("%s arg%d, ", arg.CName, i)
        }
    }
    return fmt.Sprintf("%s %s(%s)", m.Ret.CName, m.Name, decl[:len(decl)-2])
}

var temp_caller_h = template.Must(template.New("dbus_call_h").Funcs(template.FuncMap{
    "func_decl": temp_caller_func_decl,
}).Parse(`
{{range .Methods }}
{{func_decl .}};
{{end}}
`))
var temp_caller = template.Must(template.New("dbus_call").Funcs(template.FuncMap{
    "func_decl": temp_caller_func_decl,
    "get_dbus_args": func (m MethodStruct) string {
        var decl string
        for _, arg  := range m.Args {
            decl += fmt.Sprintf("%s", arg.DName)
        }
        return decl
    },
    "get_c_args": func (m MethodStruct) string {
        var decl string
        for i, _ := range m.Args {
            decl += fmt.Sprintf("arg%d, ", i)
        }
        return decl[:len(decl)-2]
    },
}).Parse(`
{{range .Methods }}
{{func_decl .}}
{
    {{if .Ret.Type}}{{.Ret.CName}} _c_retval = 0; {{end}}
    GError *error = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync({{.BusInfo.Type}},
                                                     {{.BusInfo.Flags}},
                                                     NULL,
                                                     "{{.BusInfo.Name}}",
                                                     "{{.BusInfo.Path}}",
                                                     "{{.BusInfo.Ifce}}",
                                                     NULL,
                                                     &error);
    if (error != NULL) {
        g_warning ("call {{.Name}} on {{.BusInfo.Name}} failed");
        g_error_free(error);
    }
    if (proxy != NULL) {
        GVariant* params = NULL;
        params = g_variant_new("({{get_dbus_args .}})", {{get_c_args .}});
        GVariant* retval = g_dbus_proxy_call_sync(proxy, "{{.CB.Name}}",
                                               params,
                                               G_DBUS_CALL_FLAGS_NONE,
                                               -1, NULL, NULL);
        if (retval != NULL) {
    {{if .Ret.Type}}
            g_variant_get(retval, "({{.Ret.DName}})", &_c_retval);
    {{end}}
            g_variant_unref(retval);
        }

        g_object_unref(proxy);
    }
    {{if .Ret.Type}} return _c_retval; {{end}}
}
{{end}}
`))

func DBusCall(bus BusInfoStruct, flags int, methods...MethodStruct) {
    bus.Flags = flags
    for i, _ := range methods {
        methods[i].BusInfo =&bus
    }
    info := InputInfo{
        "",
        bus,
        methods,
    }
    err := temp_caller.Execute(output_c, info)
    if err != nil {
        panic(err)
    }
    err = temp_caller_h.Execute(output_h, info)
    if err != nil {
        panic(err)
    }
  
}
const (
    FLAGS_NONE = 0
    FLAGS_DO_NOT_LOAD_PROPERTIES = (1<<0)
    FLAGS_DO_NOT_CONNECT_SIGNALS = (1<<1)
    FLAGS_DO_NOT_AUTO_START = (1<<2)
    FLAGS_GET_INVALIDATED_PROPERTIES = (1<<3)
)

func OUTPUT_END() {
    output_h.WriteString("#endif")
}

func init() {
    prefix := flag.String("prefix", "", "set up the prefix name of the generated c/h files")
    output_dir := flag.String("out", "", "set up the directory of the generated c/h files")
    flag.Parse()
    if *prefix == "" {
        panic("Must set the prefix and output_dir")
    }
    var ok error
    output_c, ok = os.Create(filepath.Join(*output_dir, *prefix + ".c"))

    output_c.WriteString(`
/*
* THIS FILE WAS AUTOMATICALLY GENERATED, DO NOT EDIT.
*
* This file was generated by the make_dbus.go script.
*/
#include <glib.h>
#include <gio/gio.h>
`)
    output_h, ok = os.Create(filepath.Join(*output_dir, *prefix + ".h"))
    output_h.WriteString(fmt.Sprintf(`
/*
* THIS FILE WAS AUTOMATICALLY GENERATED, DO NOT EDIT.
*
* This file was generated by the make_dbus.go script.
*/
#ifndef __AUTO_GEN_DBUS_%s
#define __AUTO_GEN_DBUS_%s
#include <glib.h>
`, *prefix, *prefix))
    if ok != nil {
        print(ok)
    }

}
