See `ansible/ANSIBLE.md` for general info about running ansible commands.

**NOTE: The use of single quotes is _very_ intentional to ensure that no shell interpolation happens client side**

# The Faucet isn't work!

Generally restarting the `lotus-daemon` service (will also restart fountain) will fix this issues.

```
ansible $ ansible -m shell -a 'systemctl restart lotus-daemon' fountain
```

To verify:

```
ansible $ ansible -m shell -a 'lotus wallet new' bootstrappers --limit lotus-bootstrap-0.fra.fil-test.net
```

Go to the faucet and do `send funds` (do not use curl for this step so we can verify that the website itself is working)

Verify that the funds show up in the wallet

```
ansible $ ansible -m shell -a 'lotus wallet list | xargs -L1 lotus wallet balance' bootstrappers --limit lotus-bootstrap-0.fra.fil-test.net
```

If after ~5 minutes nothing shows up put the faucet into maintenance mode to investigate further and post a message to #fil-lotus

```
lotus-infra $ ./scripts/faucet_to_maintenance.bash
```

To gain access to the facuet while in maintance mode

```
ssh -L 7777:127.0.0.1:7777 root@lotus-fountain.yyz.fil-test.net -N
```

.... more info ....

Clean up the wallet

```
ansible $ ansible -m shell -a 'lotus wallet list | xargs -I{} lotus-shed base32 wallet-{} | xargs -I{} rm $LOTUS_PATH/keystore/{}' bootstrappers --limit lotus-bootstrap-0.fra.fil-test.net
``

