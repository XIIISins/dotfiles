# Weekly check for newer upstream commits of the pinned fish_plugins. The check
# runs in the background; its result is shown on the next shell start.
status is-interactive; or return
type -q curl; or return

set -l cache (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/fish-plugin-updates
mkdir -p (dirname $cache)

if test -s $cache
  echo "fish plugin updates (bump fish_plugins, then fisher update):"
  string replace -r '^' '  ' < $cache
end

# find prints the file only when it is older than 7 days
if not test -f $cache.stamp; or test -n "$(find $cache.stamp -mtime +7)"
  touch $cache.stamp
  fish -c "fisher_outdated > $cache" >/dev/null 2>&1 &
  disown
end
