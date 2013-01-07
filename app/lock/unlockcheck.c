/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 * Maintainer:  Long Wei <yilang2007lw@gamil.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <shadow.h>
#include <unistd.h>
#include <errno.h>
#include <crypt.h>

#define _XOPEN_SOURCE
#define _GNU_SOURCE

int check_password(const char *user, const char *password)
{
    struct spwd *user_data;
 
    if(strcmp(user, "root") == 0)
    {
        fprintf(stderr, "root not allowed\n");
        return 3;
    }
 
    errno = 0;
    user_data = getspnam(user);
    if(user_data == NULL)
    {
        fprintf(stderr, "No such user %s, or error %s\n", user, strerror(errno));
        return 1;
    }

    if((strcmp(crypt(password, user_data->sp_pwdp), user_data->sp_pwdp)) != 0)
    {
        fprintf(stderr, "Auth user %s failed\n", user);
        return 2;
    }
 
    return 0;
}
 
int main(int argc, char **argv)
{
    char *user, *password;
 
    if(argc != 3){
        fprintf(stderr, "Useage: unlockcheck username password\n");
    }

    user = argv[1];
    password = argv[2];

    if(user == NULL || strcmp(user, "") == 0){
        fprintf(stderr, "User invalid:%s",strerror(errno));
        exit(2);
    }

    if(password == NULL || strcmp(password, "") == 0){
        fprintf(stderr, "Password invalid:%s",strerror(errno));
        exit(3);
    }
 
    exit(check_password(user, password));
}
