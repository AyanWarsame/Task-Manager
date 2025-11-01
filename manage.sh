#!/bin/bash

case "$1" in
    dev)
        docker-compose up --build
        ;;
    prod)
        docker-compose -f docker-compose.prod.yml up --build -d
        ;;
    stop)
        docker-compose down
        ;;
    stop-prod)
        docker-compose -f docker-compose.prod.yml down
        ;;
    logs)
        docker-compose logs -f
        ;;
    logs-backend)
        docker-compose logs -f backend
        ;;
    logs-db)
        docker-compose logs -f db
        ;;
    shell-backend)
        docker-compose exec backend bash
        ;;
    shell-db)
        docker-compose exec db bash
        ;;
    psql)
        docker-compose exec db psql -U postgres -d taskdb
        ;;
    backup)
        docker-compose exec db pg_dump -U postgres taskdb > backup_$(date +%Y%m%d_%H%M%S).sql
        echo "Backup created: backup_$(date +%Y%m%d_%H%M%S).sql"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: $0 restore <backup_file>"
            exit 1
        fi
        docker-compose exec -T db psql -U postgres -d taskdb < "$2"
        ;;
    clean)
        docker-compose down
        docker system prune -f
        ;;
    status)
        docker-compose ps
        echo ""
        docker system df
        ;;
    *)
        echo "Usage: $0 {dev|prod|stop|stop-prod|logs|logs-backend|logs-db|shell-backend|shell-db|psql|backup|restore|clean|status}"
        exit 1
        ;;
esac