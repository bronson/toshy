#!/usr/bin/env bash


# Monitor whether the user's desktop session is "Active" according to loginctl.
# D-Bus version

# Should handle the case of user remaining "logged in" but using "switch user"
# to let another user log in to their own desktop and use the screen. 
# 
# We don't want the keymapper to interfere with the other user's input or 
# with their separate usage of this or any other keymapper. So this monitoring
# service will disable the config file service while the user's session is not
# "Active" according to loginctl. 


DEBUG=1

if command -v loginctl >/dev/null 2>&1; then
    : # no-op operator
else
    echo "The \"loginctl\" command is not available. Toshy session monitor will not work here."
    exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
    : # no-op operator
else
    echo "The \"systemctl\" command is not available. Toshy session monitor will not work here."
    exit 1
fi

if command -v dbus-send >/dev/null 2>&1; then
    : # no-op operator
else
    echo "The \"dbus-send\" command is not available. Toshy session monitor will not work here."
    exit 1
fi

TOSHY_CONFIG_SVC=$(dbus-send --session --type=method_call --print-reply \
    --dest=org.freedesktop.systemd1 \
    /org/freedesktop/systemd1 \
    org.freedesktop.systemd1.Manager.GetUnit \
    string:"toshy-config.service" | grep " path " | cut -d'"' -f2
)
TOSHY_SESSION_MONITOR_SVC=$(dbus-send --session --type=method_call --print-reply \
    --dest=org.freedesktop.systemd1 \
    /org/freedesktop/systemd1 \
    org.freedesktop.systemd1.Manager.GetUnit \
    string:"toshy-session-monitor.service" | grep " path " | cut -d'"' -f2
)

if [[ $DEBUG == 1 ]]
    then
        echo -e "Service paths:\
        \n  '$TOSHY_CONFIG_SVC'\
        \n  '$TOSHY_SESSION_MONITOR_SVC'\
        \n"
fi


# If XDG_RUNTIME_DIR is not set or is empty
if [ -z "${XDG_RUNTIME_DIR}" ]; then
    echo "Toshy Config Service: XDG_RUNTIME_DIR is not set. Unable to determine where to store the marker file."
    # exit 1
else
    # Full path to the marker file
    MARKER_FILE="${XDG_RUNTIME_DIR}/toshy-service-sessmon-dbus.start"
    # Check if a marker file exists
    if [ ! -f "${MARKER_FILE}" ]; then
        # If it does not exist, wait for a certain time period
        sleep 8
        # Create the marker file to signify that the service has started once
        touch "${MARKER_FILE}"
    fi
fi


USER="$(whoami)"

# give the session info and config service a bit of time to stabilize
sleep 2

i=3
while (( i > 0 ))
    do
        if [[ $DEBUG == 1 ]]
            then
                echo "i is $i"
        fi
        (( i -= 1 ))

        # get the current session ID (number)
        SESSION_ID="$(loginctl session-status | head -n1 | cut -d' ' -f1)"

        # check the loginctl show-session metadata to see if it's "Active" (yes/no)
        SESSION_IS_ACTIVE="$(loginctl show-session "$SESSION_ID" -p Active --value)"

        # check the status of Toshy service
        SERVICE_STATUS="$(systemctl --user is-active toshy-config.service)"



        # if loginctl session is active, try to start Toshy service (only if inactive)
        if [[ "$SESSION_IS_ACTIVE" == "yes" ]]
            then
                # echo "Session for user $USER is active right now. $(date +%F_%H%M%S)" | tee -a /tmp/user-$USER.txt
                if [[ "$SERVICE_STATUS" == "inactive" ]]
                    then
                        systemctl --user start toshy-config.service > /dev/null 2>&1
                fi
        fi

        # if loginctl session is NOT active, try to stop Toshy service (only if active)
        if [[ "$SESSION_IS_ACTIVE" == "no" ]]
            then
                # echo "Session for user $USER is NOT active right now. $(date +%F_%H%M%S)" | tee -a /tmp/user-$USER.txt
                if [[ "$SERVICE_STATUS" == "active" ]]
                    then
                        systemctl --user stop toshy-config.service > /dev/null 2>&1
                fi
        fi
        sleep 3 # no need to check too frequently
        
done
