#ifndef _SETUP_FIXTURE_H_
#define _SETUP_FIXTURE_H_

extern GPtrArray *gfileDirectory ;
extern GPtrArray *gfileDocument;
extern GPtrArray *gappinfo;

extern void setup_fixture();
extern void tear_down_fixture();
extern void func_test_entry_char(char* (*func)(Entry*),Entry* variable,char* value_return);
extern void func_test_entry_arraycontainer(gboolean (*func)(Entry*,const ArrayContainer),Entry* variable,const ArrayContainer fs,gboolean value_return);

#endif