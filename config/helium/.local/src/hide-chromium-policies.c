#define _GNU_SOURCE
#include <dlfcn.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef __NR_openat2
#define __NR_openat2 437
#endif

/*
 * Hide Omarchy's Chromium machine policies from Helium without a user
 * namespace. 1Password-BrowserSupport is setgid, so glibc ignores this
 * preload for that helper and setgid still applies.
 */

static int path_blocked(const char *path) {
  return path && strstr(path, "/etc/chromium/policies") != NULL;
}

static int resolve_at(int dirfd, const char *path, char *out, size_t out_len) {
  if (!path) {
    return 0;
  }
  if (path[0] == '/') {
    snprintf(out, out_len, "%s", path);
    return 1;
  }
  if (dirfd == AT_FDCWD) {
    char cwd[PATH_MAX];
    if (!getcwd(cwd, sizeof cwd)) {
      return 0;
    }
    snprintf(out, out_len, "%s/%s", cwd, path);
    return 1;
  }
  char link[64];
  char dir[PATH_MAX];
  snprintf(link, sizeof link, "/proc/self/fd/%d", dirfd);
  ssize_t n = readlink(link, dir, sizeof dir - 1);
  if (n <= 0) {
    return 0;
  }
  dir[n] = '\0';
  snprintf(out, out_len, "%s/%s", dir, path);
  return 1;
}

static int blocked_at(int dirfd, const char *path) {
  if (path_blocked(path)) {
    return 1;
  }
  char full[PATH_MAX];
  if (!resolve_at(dirfd, path, full, sizeof full)) {
    return 0;
  }
  return path_blocked(full);
}

#define REAL(name)                                                             \
  static typeof(&name) real_##name;                                            \
  if (!real_##name) {                                                          \
    real_##name = dlsym(RTLD_NEXT, #name);                                     \
  }

int open(const char *path, int flags, ...) {
  REAL(open);
  mode_t mode = 0;
  if (flags & O_CREAT) {
    va_list ap;
    va_start(ap, flags);
    mode = va_arg(ap, mode_t);
    va_end(ap);
  }
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real_open(path, flags, mode);
}

int open64(const char *path, int flags, ...) {
  REAL(open64);
  mode_t mode = 0;
  if (flags & O_CREAT) {
    va_list ap;
    va_start(ap, flags);
    mode = va_arg(ap, mode_t);
    va_end(ap);
  }
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real_open64(path, flags, mode);
}

int openat(int dirfd, const char *path, int flags, ...) {
  REAL(openat);
  mode_t mode = 0;
  if (flags & O_CREAT) {
    va_list ap;
    va_start(ap, flags);
    mode = va_arg(ap, mode_t);
    va_end(ap);
  }
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real_openat(dirfd, path, flags, mode);
}

int openat64(int dirfd, const char *path, int flags, ...) {
  REAL(openat64);
  mode_t mode = 0;
  if (flags & O_CREAT) {
    va_list ap;
    va_start(ap, flags);
    mode = va_arg(ap, mode_t);
    va_end(ap);
  }
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real_openat64(dirfd, path, flags, mode);
}

int access(const char *path, int mode) {
  REAL(access);
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real_access(path, mode);
}

int faccessat(int dirfd, const char *path, int mode, int flags) {
  REAL(faccessat);
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real_faccessat(dirfd, path, mode, flags);
}

int stat(const char *restrict path, struct stat *restrict st) {
  REAL(stat);
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real_stat(path, st);
}

int lstat(const char *restrict path, struct stat *restrict st) {
  REAL(lstat);
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real_lstat(path, st);
}

int fstatat(int dirfd, const char *restrict path, struct stat *restrict st,
            int flags) {
  REAL(fstatat);
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real_fstatat(dirfd, path, st, flags);
}

int statx(int dirfd, const char *restrict path, int flags, unsigned mask,
          struct statx *restrict st) {
  REAL(statx);
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real_statx(dirfd, path, flags, mask, st);
}

FILE *fopen(const char *restrict path, const char *restrict mode) {
  REAL(fopen);
  if (path_blocked(path)) {
    errno = ENOENT;
    return NULL;
  }
  return real_fopen(path, mode);
}

FILE *fopen64(const char *restrict path, const char *restrict mode) {
  REAL(fopen64);
  if (path_blocked(path)) {
    errno = ENOENT;
    return NULL;
  }
  return real_fopen64(path, mode);
}

DIR *opendir(const char *path) {
  REAL(opendir);
  if (path_blocked(path)) {
    errno = ENOENT;
    return NULL;
  }
  return real_opendir(path);
}

DIR *fdopendir(int fd) {
  REAL(fdopendir);
  char link[64];
  char dir[PATH_MAX];
  snprintf(link, sizeof link, "/proc/self/fd/%d", fd);
  ssize_t n = readlink(link, dir, sizeof dir - 1);
  if (n > 0) {
    dir[n] = '\0';
    if (path_blocked(dir)) {
      errno = ENOENT;
      return NULL;
    }
  }
  return real_fdopendir(fd);
}

int openat2(int dirfd, const char *path, const struct open_how *how,
            size_t size) {
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return (int)syscall(__NR_openat2, dirfd, path, how, size);
}

/* glibc may implement stat(2) via these versioned helpers. */
int __xstat(int ver, const char *path, struct stat *st) {
  static typeof(&__xstat) real;
  if (!real) {
    real = dlsym(RTLD_NEXT, "__xstat");
  }
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real(ver, path, st);
}

int __lxstat(int ver, const char *path, struct stat *st) {
  static typeof(&__lxstat) real;
  if (!real) {
    real = dlsym(RTLD_NEXT, "__lxstat");
  }
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real(ver, path, st);
}

int __fxstatat(int ver, int dirfd, const char *path, struct stat *st,
               int flags) {
  static typeof(&__fxstatat) real;
  if (!real) {
    real = dlsym(RTLD_NEXT, "__fxstatat");
  }
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real(ver, dirfd, path, st, flags);
}

int __xstat64(int ver, const char *path, struct stat64 *st) {
  static typeof(&__xstat64) real;
  if (!real) {
    real = dlsym(RTLD_NEXT, "__xstat64");
  }
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real(ver, path, st);
}

int __lxstat64(int ver, const char *path, struct stat64 *st) {
  static typeof(&__lxstat64) real;
  if (!real) {
    real = dlsym(RTLD_NEXT, "__lxstat64");
  }
  if (path_blocked(path)) {
    errno = ENOENT;
    return -1;
  }
  return real(ver, path, st);
}

int __fxstatat64(int ver, int dirfd, const char *path, struct stat64 *st,
                 int flags) {
  static typeof(&__fxstatat64) real;
  if (!real) {
    real = dlsym(RTLD_NEXT, "__fxstatat64");
  }
  if (blocked_at(dirfd, path)) {
    errno = ENOENT;
    return -1;
  }
  return real(ver, dirfd, path, st, flags);
}
