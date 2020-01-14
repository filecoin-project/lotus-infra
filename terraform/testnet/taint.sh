#!/usr/bin/env bash

terraform12 taint 'null_resource.lotus_bootstrap_dfw[0]'
terraform12 taint 'null_resource.lotus_bootstrap_dfw[1]'
terraform12 taint 'null_resource.lotus_bootstrap_fra[0]'
terraform12 taint 'null_resource.lotus_bootstrap_fra[1]'
terraform12 taint 'null_resource.lotus_bootstrap_sin[0]'
terraform12 taint 'null_resource.lotus_bootstrap_sin[1]'
terraform12 taint 'null_resource.lotus_fountain'
terraform12 taint 'null_resource.stats'
