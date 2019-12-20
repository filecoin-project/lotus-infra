See `ansible/ANSIBLE.md` for general info about running ansible commands.

**NOTE: The use of single quotes is _very_ intentional to ensure that no shell interpolation happens client side**

# Faucet

## The Faucet isn't work!

### Check mpool stats

Check to see how many messages are in the mpool for the fountain address

```
ansible -m shell -a 'lotus mpool stat | grep $(lotus wallet default)' fountain
```

If `past` is greater than `0` this is bad contact lotus devs
If `future` is greater than `0` this is bad contact lotus devs

If `curr` is greater than `0` this is okay, just means that there is a queue of messages.

If `curr` is greater than 200, put the faucet into maintance mode and monitor the mpool till
it drops below 50

```
lotus-infra $ ./scripts/faucet_to_maintenance.bash
```

If `curr` is zero or a low number try the faucet yourself

```
ansible $ ansible -m shell -a 'lotus wallet new' bootstrappers --limit lotus-bootstrap-0.fra.fil-test.net
```

Go to the faucet and do `send funds` (do not use curl for this step so we can verify that the website itself is working)

Verify that the funds show up in the wallet

```
ansible $ ansible -m shell -a 'lotus wallet list | xargs -L1 lotus wallet balance' bootstrappers --limit lotus-bootstrap-0.fra.fil-test.net
```

While waiting, montior the mpool

```
ansible -m shell -a 'lotus mpool pending | jq "select( .Message.From == \"$(lotus wallet default)\")"' fountain
```

If after ~5 minutes nothing shows up put the faucet into maintenance mode to investigate further and post a message to #fil-lotus

```
lotus-infra $ ./scripts/faucet_to_maintenance.bash
```

To gain access to the facuet while in maintance mode

```
ssh -L 7777:127.0.0.1:7777 root@lotus-fountain.yyz.fil-test.net -N
```

Continue to investigate

Clean up the wallet

```
ansible $ ansible -m shell -a 'lotus wallet list | xargs -I{} lotus-shed base32 wallet-{} | xargs -I{} rm $LOTUS_PATH/keystore/{}' bootstrappers --limit lotus-bootstrap-0.fra.fil-test.net
``

