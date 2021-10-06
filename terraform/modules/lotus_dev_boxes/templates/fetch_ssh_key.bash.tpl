#!/bin/bash
set -e

# Notify Slack
notify_slack() {
    local message="$1"
    local slack_endpoint="$2"
}

write_script() {
    cat <<- "EOF" > /usr/local/bin/fetch_ssh_key.bash
#!/bin/bash
AUTHORIZED_KEYS="${home_dir}/.ssh/authorized_keys"
INFRA_KEY="$(cat $AUTHORIZED_KEYS | head -1)"
DEV_KEY="$(curl -s https://github.com/${github_username}.keys)"
echo "$INFRA_KEY" > $AUTHORIZED_KEYS
echo "$DEV_KEY" >> $AUTHORIZED_KEYS
chown ${ubuntu_user} $AUTHORIZED_KEYS
chmod 600 $AUTHORIZED_KEYS

EOF
    chmod +x /usr/local/bin/fetch_ssh_key.bash
}

write_systemd_service() {
    cat <<- "EOF" > /etc/systemd/system/fetch_ssh_key.service
[Unit]
Description=Fetches developer SSH keys from Github
Wants=fetch_ssh_key.timer

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fetch_ssh_key.bash "${github_username}"

[Install]
WantedBy=multi-user.target
EOF
}

write_systemd_timer() {
    cat <<- "EOF" > /etc/systemd/system/fetch_ssh_key.timer
[Unit]
Description=Refreshes developer SSH keys from Github
Requires=fetch_ssh_key.service

[Timer]
Unit=fetch_ssh_key.service
OnCalendar=Hourly

[Install]
WantedBy=timers.target
EOF
}

start_timer() {
    systemctl daemon-reload
    systemctl enable fetch_ssh_key.timer
    systemctl start fetch_ssh_key.timer
}

write_script
/usr/local/bin/fetch_ssh_key.bash "${github_username}"
write_systemd_service
write_systemd_timer
start_timer
