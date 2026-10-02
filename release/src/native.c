#include "moonbit.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* Exit the release tool with a shell-visible code. stdio is flushed so the
 * tool's own progress lines are not lost; atexit handlers are skipped. */
MOONBIT_FFI_EXPORT
void bm2_release_exit(int32_t code) {
  fflush(NULL);
  _exit((int)code);
}
