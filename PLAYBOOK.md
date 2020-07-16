See `ansible/ANSIBLE.md` for general info about running ansible commands.

**NOTE: The use of single quotes is _very_ intentional to ensure that no shell interpolation happens client side**

# Faucet

## The Faucet isn't work!

### Check that the site is served

Visit `https://faucet.<network>.fildev.network/`

```
curl -I https://faucet.<network>.fildev.network/
```

If the site is in maintance mode

```
ansible -i $hostfile -b -m file -a 'state=link src=/etc/nginx/sites-available/faucet.conf dest=/etc/nginx/sites-enabled/50-faucet.conf' faucet
ansible -i $hostfile -b -m systemd -a 'name=nginx state=reloaded' faucet
```

If there is a 502 gateway issue, ensure the `lotus-fountain` is running

```
ansible -i $hostfile -b -m shell -a 'systemctl status lotus-fountain' faucet
ansible -i $hostfile -b -m systemd -a 'name=lotus-fountain state=started' faucet
```

If the `lotus-fountain` service fails to come online you can check the logs `/var/log/lotus-fountain.log`, as well
as try to run the service manually to see what error output it produces (`journalctl -u lotus-fountain.service` isn't picking up stderr for some reason).

```
sudo su su -c bash -- fc
grep ExecStart < /etc/systemd/system/lotus-fountain.service | sed 's/.*ExecStart=//'
```

### Check mpool stats

Check to see how many messages are in the mpool for the fountain address

```
ansible -i $hostfile -b -m shell -a 'lotus mpool stat | grep $(lotus wallet default)' faucet
```

If `curr` is greater than `0` this is okay, just means that there is a queue of messages.
Messages can be mined into blocks at around 512 messages per block in a tipset

If `past` is greater than `0` this means there are messages in the mpool with a lower nonce than
the actor. Notify the development team and see if it's of interest.

----------------

If `future` is greater than `0`, this means there is a nonce gap that needs to be fixed.

Check that the `lotus-noncefix` timer is enabled and working

```
ansible -i $hostfile -b -m shell -a 'systemctl status lotus-noncefix.timer' faucet
```

If the timer is `active (waiting)`, the issue should resolve itself. Standby for the next trigger to occur
and check the mpool stats again.

If the timer is `inactive (dead)`

```
ansible -i $hostfile -b -m systemd -a 'name=lotus-noncefix.timer state=started' faucet
```

You can manually start the `lotus-noncefix` as well

```
ansible -i $hostfile -b -m systemd -a 'name=lotus-noncefix.service state=started' faucet
```

----------------

Verify that the future value is now `0`
```
ansible -i $hostfile -b -m shell -a 'lotus mpool stat | grep $(lotus wallet default)' faucet
```

----------------

If `curr` is zero or a low number try the faucet yourself

```
ansible -i $hostfile -b -m shell -a 'lotus wallet new' scratch0
```

Go to the faucet and do `send funds` (do not use curl for this step so we can verify that the website itself is working)

Verify that the funds show up in the wallet

```
ansible -i $hostfile -b -m shell -a 'lotus wallet list | xargs -L1 lotus wallet balance' scratch0
```

While waiting, monitor the mpool

```
ansible -i $hostfile -b -m shell -a 'lotus mpool pending | jq "select( .Message.From == \"$(lotus wallet default)\")"' faucet
```

If after ~5 minutes nothing shows up put the faucet into maintenance mode to investigate further and post a message to #fil-lotus

```
ansible -i $hostfile -b -m file -a 'state=absent path=/etc/nginx/sites-enabled/50-faucet.conf' faucet
ansible -i $hostfile -b -m systemd -a 'name=nginx state=reloaded' faucet
```

To gain access to the facuet while in maintance mode

```
ssh -L 7777:127.0.0.1:7777 ubuntu@faucet.<network>.fildev.network -N
```

Continue to investigate `http://localhost:7777`

------------------

Once done put the faucet back online

```
ansible -i $hostfile -b -m file -a 'state=link src=/etc/nginx/sites-available/faucet.conf dest=/etc/nginx/sites-enabled/50-faucet.conf' faucet
ansible -i $hostfile -b -m systemd -a 'name=nginx state=reloaded' faucet
```

------------------

Clean up the wallet

```
ansible -i $hostfile -b -m shell -a 'lotus wallet delete <wallet>` scratch0
```
