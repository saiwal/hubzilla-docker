#!/bin/bash

# Pull latest changes
cd /var/www/html && util/udall

# Start cron
service cron start

# Start Apache in the foreground
apache2-foreground

