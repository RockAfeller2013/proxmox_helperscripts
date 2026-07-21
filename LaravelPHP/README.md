# Laravel LXC Helper Script for Proxmox VE

> Proposal for a new Community Scripts helper (`laravel.sh`) based on the existing `caddy.sh` installer.

---

# Overview

The existing Community Scripts **Caddy** installer is an excellent starting point for hosting PHP applications.

For Laravel applications, a dedicated helper script would provide a complete, production-ready development and deployment environment by installing all required dependencies automatically.

Proposed helper script:

```
laravel.sh
```

This helper would follow the same structure and coding standards as the Community Scripts project while extending the functionality specifically for Laravel.

---

# Architecture

```
Laravel LXC

├── Debian 13
├── Caddy
├── PHP 8.4 FPM
├── Composer
├── Git
├── Node.js LTS
├── npm
├── pnpm
├── Redis
├── Supervisor
├── Laravel
└── Automatic HTTPS
```

---

# Proposed Software Stack

| Component | Purpose |
|-----------|---------|
| Debian 13 | Base operating system |
| Caddy | Web server |
| PHP 8.4 | Runtime |
| PHP-FPM | PHP Process Manager |
| Composer | PHP package manager |
| Git | Source control |
| Node.js LTS | Frontend build tools |
| npm | JavaScript package manager |
| pnpm | Faster package manager |
| Bun (Optional) | JavaScript runtime |
| Redis | Cache / Queue |
| Supervisor | Queue worker management |
| OPcache | PHP performance |
| unzip | Composer packages |
| Image Libraries | GD / Imagick support |

---

# PHP Extensions

The helper would install the common Laravel extensions.

| Extension | Required |
|------------|----------|
| bcmath | ✔ |
| curl | ✔ |
| fileinfo | ✔ |
| gd | ✔ |
| intl | ✔ |
| mbstring | ✔ |
| openssl | ✔ |
| pdo_mysql | ✔ |
| pdo_pgsql | Optional |
| redis | ✔ |
| sqlite3 | Optional |
| xml | ✔ |
| zip | ✔ |
| imagick | Optional |

---

# Services Installed

| Service | Purpose |
|----------|---------|
| Caddy | HTTP Server |
| PHP-FPM | PHP Execution |
| Redis | Cache & Queues |
| Supervisor | Queue Workers |
| Systemd Scheduler | Laravel Scheduler |

---

# Automatic Configuration

The helper should automatically configure:

- Caddy virtual host
- PHP-FPM
- Redis
- OPcache
- Queue worker
- Laravel scheduler
- Automatic HTTPS
- Firewall (optional)
- Log rotation

---

# Deployment Options

At the end of the installation the script could prompt:

```
Create a new Laravel project?

1) No
2) Laravel Starter
3) Laravel Breeze
4) Laravel Jetstream
5) Laravel + Filament
6) Existing Git Repository
```

---

# Existing Git Repository Workflow

If the user selects **Existing Git Repository**, the helper would perform:

1. Clone repository
2. Install Composer dependencies
3. Install Node packages
4. Build frontend assets
5. Configure `.env`
6. Generate `APP_KEY`
7. Set file permissions
8. Configure Caddy
9. Enable queue workers
10. Enable scheduler
11. Restart services

The application would be immediately accessible.

---

# Comparison

| Feature | Caddy Helper | Proposed Laravel Helper |
|----------|--------------|-------------------------|
| Debian LXC | ✅ | ✅ |
| Caddy | ✅ | ✅ |
| Automatic HTTPS | ✅ | ✅ |
| PHP 8.4 | Partial | ✅ |
| PHP-FPM | Partial | ✅ |
| Composer | ❌ | ✅ |
| Git | ❌ | ✅ |
| Node.js LTS | ❌ | ✅ |
| npm | ❌ | ✅ |
| pnpm | ❌ | ✅ |
| Bun | ❌ | Optional |
| Redis | ❌ | ✅ |
| Supervisor | ❌ | ✅ |
| Laravel Installer | ❌ | ✅ |
| Queue Workers | ❌ | ✅ |
| Scheduler | ❌ | ✅ |
| OPcache | ❌ | ✅ |
| PHP Extensions | Basic | Full Laravel Stack |
| Git Deployment | ❌ | ✅ |
| Laravel Project Creation | ❌ | ✅ |
| Production Ready | Basic PHP | ✅ |

---

# Optional Enhancements

Future versions of the helper could optionally install:

| Component | Purpose |
|-----------|---------|
| PostgreSQL | Database |
| MariaDB | Database |
| Meilisearch | Full-text search |
| Typesense | Search |
| MinIO | S3-compatible storage |
| Mailpit | Local mail testing |
| Horizon | Queue dashboard |
| Telescope | Application debugging |
| Reverb | WebSockets |
| Octane | High-performance Laravel runtime |
| FrankenPHP | Alternative to PHP-FPM |

---

# Recommended Option

Instead of using traditional PHP-FPM, consider supporting **FrankenPHP** as an installation option.

Advantages include:

- Built on Caddy
- No separate PHP-FPM service
- Lower memory usage
- Faster request handling
- Native HTTP/3 support
- Automatic HTTPS
- Excellent Laravel Octane integration
- Simpler configuration
- Fewer moving parts

Ideal for:

- Laravel 12+
- Livewire
- Filament
- REST APIs
- SaaS applications
- High-concurrency workloads

---

# Conclusion

A dedicated `laravel.sh` helper would extend the Community Scripts ecosystem by providing a complete Laravel deployment environment while maintaining the same installation experience as existing helpers such as `caddy.sh`.

This would enable users to provision a production-ready Laravel LXC in minutes with minimal manual configuration.
