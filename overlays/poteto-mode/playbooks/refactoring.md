## Steps

- **After** "A speculative cleanup that": before you prototype a change to your own config to make a vendor tool behave, list the vendor's own switches from its installed artifact: run it with `--debug`, find the call that escaped, and grep the installed bundle for the env vars it reads. One switch can delete the whole prototype.
