/*
 * Copyright (C) 2009 Chris McClelland
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef MAKESTUFF_H
#define MAKESTUFF_H

#ifndef __cplusplus
	#ifdef WIN32
		typedef int bool;
		enum {
			false = 0,
			true = 1
		};
	#else
		#include <stdbool.h>
	#endif
#endif

#ifdef WIN32
	#define WARN_UNUSED_RESULT
	#define DLLEXPORT(t) __declspec(dllexport) t __stdcall
#else
	#define WARN_UNUSED_RESULT __attribute__((warn_unused_result))
	#define DLLEXPORT(t) t
#endif

#ifndef NULL
	#define NULL ((void*)0)
#endif

typedef unsigned char      uint8;
typedef unsigned short     uint16;
typedef unsigned long      uint32;
#ifndef __cplusplus
	typedef unsigned long long uint64;
#endif

typedef signed char        int8;
typedef signed short       int16;
typedef signed long        int32;
#ifndef __cplusplus
	typedef signed long long   int64;
#endif

typedef unsigned int       bitfield;

#endif
