source <(grep LARADOCK_SERVICES .env)
docker-compose up -d $LARADOCK_SERVICES --build
