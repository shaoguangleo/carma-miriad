/************************************************************************/
/*									*/
/* This handles errors from the c and fortran routines but will not     */
/*   exit the python module                     			*/
/* This module is derived from bug.c					*/
/*  History:								*/
/*    dnf      06jan09 initial version                                  */
/************************************************************************/

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "miriad.h"

static char *errmsg_c(int n);
static int  handle_bug_cleanup(int d, char s, Const char *m);

static char *Name = NULL;     /* a slot to store the program name       */

typedef void (*proc)(void);  /* helper definition for function pointers */

static proc bug_cleanup=NULL; /* external bug handler, if any           */
static char *bug_message=0;   /* last message                           */ 
static char bug_severity=0;   /* last severity level (i,w,e or f)       */


#define MAXMSG 256
static char msg[MAXMSG];      /* formatted message for bugv_c()         */


/************************************************************************/
char *bugmessage_c(void)
/** bugmessage_c -- return last fatal error message string              */
/*& pjt                                                                 */
/*: error-handling                                                      */
/*+                                                                    
    This routine does not have a FORTRAN counterpart, as it is normally 
    only called by C clients who have set their own error handler if
    for some reason they don't like the MIRIAD one (e.g. C++ or java
    exceptions, or NEMO's error handler. This way the bugrecover handler
    can call this routine to retrieve the last fatal error message. 

    bugrecover_c(my_handler);
    
    void my_handler(void) {
       char *m = bugmessage_c();
       printf("RECOVERED: %s\n",m);
    }
    ..                                                                  */
/*--                                                                    */
/*----------------------------------------------------------------------*/
{
  return bug_message;
}

/************************************************************************/
char bugseverity_c(void)
/** bugseverity_c -- return last severity level                         */
/*& pjt                                                                 */
/*: error-handling                                                      */
/*+                                                                    
    This routine does not have a FORTRAN counterpart, as it is normally 
    only called by C clients who have set their own error handler if
    for some reason they don't like the MIRIAD one (e.g. C++ or java
    exceptions, or NEMO's error handler. This way the bugrecover handler
    can call this routine to retrieve the last severity level 

    bugrecover_c(my_handler);
    
    void my_handler(void) {
       char  s = bugseverity_c();
       char *m = bugmessage_c();
       printf("RECOVERED: (%c) %s\n",s,m);
       if (s=='f') exit(1);
    }
    ..                                                                  */
/*--                                                                    */
/*----------------------------------------------------------------------*/
{
  return bug_severity;
}

/************************************************************************/
void bugrecover_c(void (*cl)(void))
/** bugrecover_c -- bypass fatal bug calls for alien clients            */
/*& pjt                                                                 */
/*: error-handling                                                      */
/*+                                                                    
    This routine does not have a FORTRAN counterpart, as it is normally 
    only called by C clients who need to set their own error handler if
    for some reason they don't like the MIRIAD one (e.g. C++ or java
    exceptions, or NEMO's error handler 
    Example of usage:

    void my_handler(void) {
        ....
    }


    ..
    bugrecover_c(my_handler);
    ..                                                                  */
/*--                                                                    */
/*----------------------------------------------------------------------*/
{
    bug_cleanup = cl;
    if (bug_message) free(bug_message);
    bug_message = strdup("no bug_message has been set yet");
}

/************************************************************************/
void buglabel_c(Const char *name)
/** buglabel -- Give the "program name" to be used as a label in messages. */
/*& pjt									*/
/*: error-handling							*/
/*+ FORTRAN call sequence:
	subroutine buglabel(name)

	implicit none
	character name*(*)

  Give the name that is to be used as a label in error messages. Usually
  this is the program name and should be set by the user interface.

  Input:
    name	The name to be given as a label in error messages.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  if(Name != NULL)free(Name);
  Name = malloc(strlen(name)+1);
  strcpy(Name,name);
}
/************************************************************************/
void bug_c(char s,Const char *m)
/** bug -- Issue an error message, given by the caller.			*/
/*& pjt									*/
/*: error-handling							*/
/*+ FORTRAN call sequence:
	subroutine bug(severity,message)

	implicit none
	character severity*1
	character message*(*)

  Output the error message given by the caller, and abort if needed.

  Input:
    severity	Error severity. Can be one of 'i', 'w', 'e' or 'f'
		for "informational", "warning", "error", or "fatal"
    message	The error message text.					*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  char *p;
  int doabort;

  doabort = 0;
  if      (s == 'i' || s == 'I') p = "Informational";
  else if (s == 'w' || s == 'W') p = "Warning";
  else if (s == 'e' || s == 'E') p = "Error";
  else {doabort = 1;		 p = "Fatal Error"; }

  if (!bug_cleanup)
  {
    if ( Name == NULL )
      buglabel_c("(NOT SET)");
    fprintf(stderr,"### %s [%s]:  %s\n",p,Name,m);
  }
  handle_bug_cleanup(0,s,m);
// raise a signal if this is a fatal error - this passes to the python
//   signal catcher and allows python to continue without crashing
  if(doabort){
      signal(0,NULL);
  }
}
/************************************************************************/
void bugv_c(char s,Const char *m, ...)
/** bugv_c -- Issue a dynamic error message, given by the caller.	*/
/*& pjt									*/
/*: error-handling							*/
/*+ C call sequence:
	bugv_c(severity,message,....)

  Output the error message given by the caller, and abort if needed.
  Note this routine has no counterpart in FORTRAN.

  Input:
    severity	Error severity character. 
                Can be one of 'i', 'w', 'e' or 'f'
		for "informational", "warning", "error", or "fatal"
    message	The error message string, can contain %-printf style 
                directives, as used by the following arguments.
     ...         Optional argument, in the printf() style               */
/*--									*/
/*----------------------------------------------------------------------*/
{
  va_list ap;
  char *p;
  int doabort,len;

  doabort = 0;
  if      (s == 'i' || s == 'I') p = "Informational";
  else if (s == 'w' || s == 'W') p = "Warning";
  else if (s == 'e' || s == 'E') p = "Error";
  else {doabort = 1;		 p = "Fatal Error"; }

  va_start(ap,m);

  if ( Name == NULL )
    buglabel_c("(NOT SET)");

  snprintf(msg,MAXMSG,"### %s [%s]: ",p,Name);
  len = strlen(msg);
  vsnprintf(&msg[len],MAXMSG-len,m,ap);
  va_end(ap);

  if (!bug_cleanup)
    fprintf(stderr,"%s\n",msg);

  handle_bug_cleanup(0,s,&msg[len]);
// raise a signal if this is a fatal error - this passes to the python
//   signal catcher and allows python to continue without crashing
  if(doabort){
      signal(0,NULL);
  }
}

/************************************************************************/
void bugno_c(char s,int n)
/** bugno -- Issue an error message, given a system error number.	*/
/*& pjt									*/
/*: error-handling							*/
/*+ FORTRAN call sequence:
	subroutine bugno(severity,errno)

	implicit none
	character severity*1
	integer errno

  Output the error message associated with a particular error number.

  Input:
    severity	Error severity. Can be one of 'i', 'w', 'e' or 'f'
		for "informational", "warning", "error", or "fatal"
    errno	host error number.					*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  if (n == -1)bug_c(s,"End of file detected");
  else bug_c(s,errmsg_c(n));
}
/************************************************************************/
static char *errmsg_c(int n)
/*
  Return the error message associated with some error number.
------------------------------------------------------------------------*/
{
/* check for linux leaves this compat with old style build
 * this should be removed in favor of HAVE_STRERROR once
 * is only supported using autotools/configure
 */
#if defined(linux) || (defined(HAVE_STRERROR) && HAVE_STRERROR)
  /* new POSIX.1 style, 20 years old now... (1988) */
  return strerror(n);
#else
  /* very old style code -- stdio.h is supposed to supply this */
#  if 0
  extern int sys_nerr;
  extern char *sys_errlist[];
#  endif
  if(n > 0 && n <= sys_nerr)return((char *)sys_errlist[n]);
  else {
    sprintf(msg,"Unknown error with number %d detected.",n);
    return msg;
  }
#endif
}
/************************************************************************/
static int handle_bug_cleanup(int doabort, char s, Const char *m)
/*
  Handle cleaning up a bug 
------------------------------------------------------------------------*/
{
  if (bug_cleanup) {
    if (bug_message) free(bug_message);
    bug_message = strdup(m);      /* save last message */
    bug_severity = s;             /* save last severity */
    (*bug_cleanup)();             /* call handler ; this may exit */
    if (doabort)                  /* if it got here, handler didn't exit */
      fprintf(stderr,"### handle_bug_cleanup: WARNING: code should not come here\n");
    return 1;
  }
  return 0;
}

int MAIN__( )
{ return(0);
}
