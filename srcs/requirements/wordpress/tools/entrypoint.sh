#!/bin/bash
set -e

# Démarre php-fpm en arrière-plan
php-fpm7.4 -F &

# Attend php-fpm
until nc -z localhost 9000; do
    echo "Waiting for php-fpm..."
    sleep 1
done

# Execute le setup WordPress
/setup.sh

# Garde le container actif
tail -f /dev/null