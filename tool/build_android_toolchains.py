"""Builds android/app/src/main/assets/toolchains.zip from Termux's arm64 packages.

Usage:  python tool/build_android_toolchains.py [package ...]      (default: tcc ndk-sysroot python)
Always adds avr/ (Arduino: Alpine's avr-gcc + the Arduino core, see avr_files).

Termux builds are made for Android (bionic libc), so they run on phones as-is.
Their paths are rooted at /data/data/com.termux/files/usr; we strip that prefix and the
app points the tools at its own folder with flags/env vars instead (see toolchains.dart).
Needs Python 3.14+ (tarfile zstd support). Downloads are cached in build/termux_debs/.
"""
import io
import os
import posixpath
import re
import struct
import sys
import tarfile
import urllib.request
import zipfile

REPO = "https://packages-cf.termux.dev/apt/termux-main"
INDEX = f"{REPO}/dists/stable/main/binary-aarch64/Packages"
PREFIX = "data/data/com.termux/files/usr/"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "build", "termux_debs")
OUT = os.path.join(ROOT, "android", "app", "src", "main", "assets", "toolchains.zip")

# Not needed to compile/run student code; keeps the APK small.
SKIP = re.compile(
    r"^(share/(doc|man|info|locale|licenses)/|lib/python3\.\d+/(test|idlelib|turtledemo|tkinter|ensurepip|lib2to3)/"
    r"|lib/pkgconfig/|etc/"
    # PHP / MariaDB: only php, mariadbd and the mariadb client are used.
    r"|include/(php|mariadb|mysql)/|lib/build/|lib/mysql/plugin/|share/(aclocal|mariadb/mysql-test|mysql-test)/"
    r"|bin/(phpdbg|php-cgi|phpize|php-config|aria_|myisam|mysql|mariadb[-_]|mariadbd-|innochecksum|msql2mysql|my_print|mbstream"
    r"|mariabackup|perror|replace|resolve|wsrep|galera|sst)"
    # Mono: the C# compiler (mcs) and everyday class libraries, not WinForms/ASP.NET/VB/Roslyn.
    r"|lib/mono/(\d[\d.]*-api|msbuild|xbuild|xbuild-frameworks|monodoc|lldb|mono-configuration-crypto)/"
    r"|lib/mono/gac/(System\.Windows\.Forms|System\.Web|System\.Data\.Entity|Microsoft\.VisualBasic|System\.ServiceModel"
    r"|Microsoft\.Build|monodoc|System\.Design|System\.Drawing\.Design|Mono\.WebBrowser)"
    r"|lib/mono/4\.5/(Microsoft\.CodeAnalysis|sqlmetal|csc|vbc|Microsoft\.Build|xbuild|msbuild)"
    r"|.*\.pdb$|.*\.mdb$"
    r"|share/java/android-\d+\.jar|bin/ecj-\d+)"  # ecj: one android.jar is enough
)
# Base packages every Termux install has; nothing we bundle needs their contents.
IGNORE_DEPS = {"termux-tools", "termux-keyring", "termux-licenses", "bash", "coreutils", "dash"}


def fetch(url, dest=None):
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "curl/8"})  # CDN 403s Python's default
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            if dest:
                with open(dest, "wb") as f:
                    f.write(data)
            return data
        except OSError as e:
            print(f"  retry {attempt + 1}: {e}")
    raise SystemExit(f"download failed: {url}")


def parse_index(text):
    pkgs = {}
    for block in text.split("\n\n"):
        fields = dict(re.findall(r"^([\w-]+): (.*)$", block, re.M))
        if "Package" in fields:
            pkgs[fields["Package"]] = fields
    return pkgs


def resolve(pkgs, wanted):
    order, todo = [], list(wanted)
    while todo:
        name = todo.pop()
        if name in order or name in IGNORE_DEPS:
            continue
        if name not in pkgs:
            raise SystemExit(f"unknown package: {name}")
        order.append(name)
        for dep in filter(None, pkgs[name].get("Depends", "").split(",")):
            todo.append(re.split(r"[\s(|]", dep.strip())[0])  # first alternative, no version
    return order


def soname(data):
    """DT_SONAME of a 64-bit ELF shared library (the name the loader looks for), else None."""
    if data[:5] != b"\x7fELF\x02":
        return None
    shoff, = struct.unpack_from("<Q", data, 0x28)
    shentsize, shnum = struct.unpack_from("<HH", data, 0x3A)
    secs = [struct.unpack_from("<IIQQQQIIQQ", data, shoff + i * shentsize) for i in range(shnum)]
    for s in secs:
        if s[1] == 6:  # SHT_DYNAMIC; s[6] = its string table
            for off in range(s[4], s[4] + s[5], 16):
                tag, val = struct.unpack_from("<qQ", data, off)
                if tag == 14:  # DT_SONAME
                    at = secs[s[6]][4] + val
                    return data[at:data.index(b"\0", at)].decode()
                if tag == 0:
                    break
    return None


def deb_data(deb):
    """Returns the data.tar.* member of a .deb (an `ar` archive)."""
    assert deb[:8] == b"!<arch>\n"
    pos = 8
    while pos < len(deb):
        name, size = deb[pos:pos + 16].decode().strip(), int(deb[pos + 48:pos + 58])
        body = deb[pos + 60:pos + 60 + size]
        if name.startswith("data.tar"):
            return body
        pos += 60 + size + (size & 1)
    raise ValueError("no data.tar in deb")


# --- Arduino (avr/) -------------------------------------------------------------------
# Termux has no avr-gcc, so take Alpine's arm64 build (musl). Android lacks the musl loader
# at /lib/ld-musl-aarch64.so.1, so each program becomes a tiny sh script that runs the real
# one (<name>.elf) through the bundled loader; gcc execs cc1plus/as/ld by name and gets the
# script. Pruned to ATmega328P (Uno/Nano): ~75 MB unpacked, ~29 MB in the zip.
ALPINE = "https://dl-cdn.alpinelinux.org/alpine/v3.22"
ALPINE_CACHE = os.path.join(ROOT, "build", "alpine_apks")
ARDUINO_AVR = os.path.join(ROOT, "toolchains", "arduino", "data", "packages", "arduino", "hardware", "avr")
GCC = r"usr/lib/gcc/avr/[\d.]+/"
AVR_KEEP = re.compile(
    rf"^(usr/bin/avr-(gcc|c\+\+)|usr/avr/bin/(as|ld|objcopy|ar)|{GCC}(cc1|cc1plus|collect2|liblto_plugin\.so)"
    rf"|{GCC}(avr5|include|include-fixed)/.*|{GCC}device-specs/specs-atmega328p|usr/avr/lib/ldscripts/avr5\..*"
    r"|usr/avr/lib/avr5/[^/]+|usr/avr/include/(?!avr/io).*|usr/avr/include/avr/(io|iom328p)\.h"
    r"|usr/lib/lib(gcc_s|gmp|isl|mpc|mpfr|stdc\+\+|z|zstd)\.so\.\d+|lib/ld-musl-aarch64\.so\.1)$"
)


def alpine_index():
    pkgs, provides = {}, {}
    for repo in ("main", "community"):
        data = fetch(f"{ALPINE}/{repo}/aarch64/APKINDEX.tar.gz")
        with tarfile.open(fileobj=io.BytesIO(data)) as t:
            for block in t.extractfile("APKINDEX").read().decode().split("\n\n"):
                f = dict(line.split(":", 1) for line in block.splitlines() if ":" in line)
                if "P" in f:
                    f["repo"] = repo
                    pkgs[f["P"]] = f
                    for p in f.get("p", "").split():
                        provides[p.split("=")[0]] = f["P"]
    return pkgs, provides


def avr_files():
    pkgs, provides = alpine_index()
    names, todo = [], ["gcc-avr", "binutils-avr", "avr-libc"]
    while todo:
        name = provides.get(todo[-1], todo.pop())
        if name not in names:
            names.append(name)
            todo += [re.split(r"[=<>]", d)[0] for d in pkgs[name].get("D", "").split() if not d.startswith("!")]
    print("alpine:", " ".join(sorted(names)))

    os.makedirs(ALPINE_CACHE, exist_ok=True)
    raw = {}
    for name in names:
        fn = f"{name}-{pkgs[name]['V']}.apk"
        path = os.path.join(ALPINE_CACHE, fn)
        if not os.path.exists(path):
            print("download", fn)
            fetch(f"{ALPINE}/{pkgs[name]['repo']}/aarch64/{fn}", path)
        with open(path, "rb") as f, tarfile.open(fileobj=io.BytesIO(f.read()), mode="r:gz") as tar:  # gzip streams: sig, control, data
            for m in tar:
                if m.issym():
                    raw[m.name] = ("link", posixpath.normpath(posixpath.join(posixpath.dirname(m.name), m.linkname)))
                elif m.isfile() and not m.name.startswith("."):
                    raw[m.name] = ("file", tar.extractfile(m).read())

    out = {}
    for name, (kind, val) in raw.items():
        if not AVR_KEEP.match(name):
            continue
        data = raw[val][1] if kind == "link" else val
        dest = "avr/" + name.removeprefix("usr/")  # lib/ld-musl... lands in avr/lib/ too
        if data[:4] == b"\x7fELF" and data[18] == 183 and data[16] in (2, 3) and ".so" not in name:  # arm64 program
            lib = posixpath.relpath("avr/lib", posixpath.dirname(dest))
            out[dest + ".elf"] = data
            out[dest] = (f'#!/system/bin/sh\nL="${{0%/*}}/{lib}"\n'
                         f'exec "$L/ld-musl-aarch64.so.1" --library-path "$L" "$0.elf" "$@"\n').encode()
        else:
            out[dest] = data

    # The Arduino core sources, from the arduino-cli install the PC build already uses.
    core = os.path.join(ARDUINO_AVR, sorted(os.listdir(ARDUINO_AVR))[-1])
    for src, dest in [("cores/arduino", "avr/core"), ("variants/standard", "avr/variants/standard"),
                      ("variants/eightanaloginputs", "avr/variants/eightanaloginputs")]:
        for dp, _, fs in os.walk(os.path.join(core, src)):
            for f in fs:
                rel = os.path.relpath(os.path.join(dp, f), os.path.join(core, src)).replace(os.sep, "/")
                with open(os.path.join(dp, f), "rb") as fh:
                    out[f"{dest}/{rel}"] = fh.read()
    with open(os.path.join(ROOT, "tool", "avr_build.sh"), "rb") as fh:
        out["avr/build.sh"] = fh.read().replace(b"\r\n", b"\n")
    return out


def main():
    # ecj+dx: Java on Android's own VM; mono: C#; php+mariadb: the PHP tile with MySQL.
    wanted = sys.argv[1:] or ["tcc", "ndk-sysroot", "python", "ecj", "dx", "mono", "php", "mariadb"]
    os.makedirs(CACHE, exist_ok=True)
    pkgs = parse_index(fetch(INDEX).decode())
    names = resolve(pkgs, wanted)
    print("packages:", " ".join(sorted(names)))

    files, links = {}, {}
    for name in names:
        rel = pkgs[name]["Filename"]
        path = os.path.join(CACHE, posixpath.basename(rel))
        if not os.path.exists(path):
            print("download", rel)
            fetch(f"{REPO}/{rel}", path)
        with open(path, "rb") as f, tarfile.open(fileobj=io.BytesIO(deb_data(f.read())), mode="r:*") as tar:
            for m in tar:
                p = m.name.lstrip("./")
                if not p.startswith(PREFIX):
                    continue
                p = p[len(PREFIX):]
                if not p or SKIP.match(p):
                    continue
                if m.issym():
                    links[p] = posixpath.normpath(posixpath.join(posixpath.dirname(p), m.linkname)) \
                        if not m.linkname.startswith("/") else m.linkname.split(PREFIX, 1)[-1]
                elif m.isfile():
                    files[p] = tar.extractfile(m).read()

    # Zip has no portable symlinks: store a copy of each link's target...
    for _ in range(10):
        for p, target in list(links.items()):
            if target in files:
                files[p] = files[target]
                del links[p]
    for p, target in links.items():
        print(f"  dropped dangling link {p} -> {target}")
    # ...but only one copy where the others are never looked up: a shared library is loaded by
    # its soname (libicudata.so.78, not .so or .so.78.3), and Mono loads lib/mono/4.5, not the gac.
    same = {}
    for p, data in files.items():
        same.setdefault(id(data), []).append(p)
    for names in same.values():
        mono = [n for n in names if n.startswith("lib/mono/4.5/")]
        so = soname(files[names[0]])
        libs = [n for n in names if n.startswith("lib/") and posixpath.basename(n) == so]
        keep = (mono or libs) if len(names) > 1 and (mono or libs) else names
        for n in names:
            if n not in keep:
                del files[n]
    # Mono's file APIs P/Invoke "System.Native"; Termux maps that to libmono-native.so in
    # etc/mono/config (skipped, Termux paths), so give the library that name too.
    if "lib/libmono-native.so" in files:
        files["lib/libSystem.Native.so"] = files["lib/libmono-native.so"]
    files.update(avr_files())
    with open(os.path.join(ROOT, "tool", "web_serve.sh"), "rb") as fh:
        files["web/serve.sh"] = fh.read().replace(b"\r\n", b"\n")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in sorted(files):
            z.writestr(p, files[p])
    print(f"wrote {OUT}: {len(files)} files, {os.path.getsize(OUT) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
