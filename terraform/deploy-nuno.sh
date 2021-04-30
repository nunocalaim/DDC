#!/bin/bash

terraform init
terraform apply -var-file=prod-nuno.tfvars
