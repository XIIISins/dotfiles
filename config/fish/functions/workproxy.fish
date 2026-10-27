function workproxy
    # SOCKS5 proxy through the work laptop (ssh host `workproxy`, see below), for reaching
    # internal pages from this machine while WFH; point a Zen profile or FoxyProxy at it
    set -l port 1080
    set -q WORKPROXY_PORT; and set port $WORKPROXY_PORT
    # work-laptop localhost ports to expose on the same local port (the startpage); the
    # browser never proxies localhost, so these need a real forward, not the SOCKS listener
    set -l ports 8080
    set -q WORKPROXY_PORTS; and set ports (string split ' ' -- $WORKPROXY_PORTS)
    set -l forwards
    for p in $ports
        set -a forwards -L $p:localhost:$p
    end
    set -l sock $HOME/.ssh/cm-workproxy.sock
    set -l cmd status
    test (count $argv) -gt 0; and set cmd $argv[1]

    switch $cmd
        case start
            if ssh -S $sock -O check workproxy 2>/dev/null
                echo "workproxy: already running on localhost:$port"
                return
            end
            # master connection in the background: -N no remote command, -D the SOCKS listener,
            # ExitOnForwardFailure so a busy port is an error instead of a silent no-proxy
            ssh -f -N -D $port $forwards -o ExitOnForwardFailure=yes \
                -o ControlMaster=yes -o ControlPath=$sock workproxy
            or begin
                echo "workproxy: could not start (Remote Login on and the work laptop awake? ports $port $ports free here?)" >&2
                return 1
            end
            echo "workproxy: SOCKS5 on localhost:$port, forwarding localhost:$ports"
        case stop
            ssh -S $sock -O exit workproxy 2>/dev/null
            or echo "workproxy: not running"
        case status
            if ssh -S $sock -O check workproxy 2>/dev/null
                echo "workproxy: up, SOCKS5 on localhost:$port, forwarding localhost:$ports"
            else
                echo "workproxy: down"
                return 1
            end
        case '*'
            echo "usage: workproxy [start|stop|status]

SOCKS5 proxy on localhost:$port (WORKPROXY_PORT) through the work laptop, plus the work
laptop's localhost:$ports (WORKPROXY_PORTS, space-separated) on the same local ports.
The ssh host `workproxy` lives in ~/.ssh/config.d/workproxy (machine-local)." >&2
            return 1
    end
end
