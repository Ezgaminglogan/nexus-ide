#!/system/bin/sh
# NEXUS IDE PHP tile on phones; packed as web/serve.sh by build_android_toolchains.py.
# Starts MariaDB (MySQL) in the background once, then PHP's built-in server in the student's
# folder until Stop. MariaDB keeps running between runs, so saved rows stay.
# ponytail: no grant tables (root, no password, local only); add mariadb-install-db if accounts matter.
T=${0%/*}/..
DATA=$HOME/.mariadb
mkdir -p "$DATA/nexus" # a MariaDB database is a folder: `nexus` exists from the start

if ! kill -0 "$(cat "$DATA/server.pid" 2>/dev/null)" 2>/dev/null; then
  echo "Starting MySQL (MariaDB)..."
  "$T/bin/mariadbd" --no-defaults --basedir="$T" --datadir="$DATA" --pid-file="$DATA/server.pid" \
    --socket="$TMPDIR/mysql.sock" --bind-address=127.0.0.1 --port=3306 --skip-grant-tables \
    --lc-messages-dir="$T/share/mariadb" --plugin-dir="$T/lib/mysql/plugin" \
    --innodb-buffer-pool-size=16M --skip-log-bin >"$DATA/server.log" 2>&1 &
  i=0
  while [ $i -lt 40 ] && ! [ -S "$TMPDIR/mysql.sock" ]; do sleep 0.25; i=$((i + 1)); done
  [ -S "$TMPDIR/mysql.sock" ] || { echo "MySQL did not start:"; tail -5 "$DATA/server.log"; }
fi

echo "PHP server on http://127.0.0.1:8080 (press Preview)"
# Termux's PHP has its own /data/data/com.termux paths baked in: point them at ours.
exec "$T/bin/php" -d opcache.lockfile_path="$TMPDIR" -d sys_temp_dir="$TMPDIR" -d upload_tmp_dir="$TMPDIR" \
  -d session.save_path="$TMPDIR" -S 127.0.0.1:8080 -t .
