# Open-Source WHMCS Alternatives

Free, self-hosted alternatives to [WHMCS](https://www.whmcs.com/) for managing customers, billing, subscriptions, payments, and hosting services.

## 1. FOSSBilling

**Best for:** General WHMCS replacement.

- Free and self-hosted.
- PHP-based billing and client management.
- Customer accounts and invoicing.
- Payment processing integrations.
- Hosting automation.

- Website: https://fossbilling.org/
- GitHub: https://github.com/FOSSBilling/FOSSBilling
- License: Apache 2.0

## 2. Paymenter

**Best for:** Laravel-based hosting billing.

- Free and self-hosted.
- Built with Laravel.
- Customer and billing management.
- Hosting and digital service sales.
- Extension-based integrations and service provisioning.

- Website: https://paymenter.org/
- GitHub: https://github.com/Paymenter/Paymenter
- License: MIT

## 3. Kill Bill

**Best for:** Custom subscription billing systems.

- Free and self-hosted.
- Subscription and recurring billing.
- API-driven architecture.
- Payment integrations.
- Suitable for custom billing applications.

- Website: https://killbill.io/
- GitHub: https://github.com/killbill/killbill

Note: Kill Bill requires additional development to provide a complete WHMCS-style customer portal.

## Feature Comparison

| Feature | FOSSBilling | Paymenter | Kill Bill |
|---|---|---|---|
| Self-hosted | Yes | Yes | Yes |
| Open source | Yes | Yes | Yes |
| Customer management | Yes | Yes | Custom integration |
| Invoicing and payments | Yes | Yes | Yes |
| Recurring subscriptions | Yes | Yes | Yes |
| Hosting provisioning | Yes | Extensions | Custom integration |
| Complete customer portal | Closest fit | Hosting-focused | Requires development |
| Laravel-based | No | Yes | No |

## Recommendation

For an MSP/MSSP business:

- **FOSSBilling:** Start here for a ready-made billing and customer management platform.
- **Paymenter:** Choose this if Laravel customisation and application development are priorities.
- **Kill Bill:** Choose this if you need a custom subscription billing engine.

## Production Considerations

Before deploying, verify:

- Payment gateway support.
- Domain registrar integrations.
- Hosting control panel provisioning.
- Customer support and ticketing.
- Tax invoices and Australian GST requirements.
- Multi-tenant requirements.
- Backup, upgrade, and security processes.

Do not assume any alternative provides every WHMCS feature. Validate the required integrations before production deployment.

# Open-Source cPanel Alternatives (Laravel/PHP)

Open-source alternatives to cPanel for managing web hosting, domains, databases, email, DNS, SSL certificates and server infrastructure.

## 1. Laravel-Based Hosting Control Panels

### Jabali Panel

**Best to investigate:** Laravel-based hosting control panel.

- Built with Laravel, Filament and Livewire.
- WordPress and PHP hosting.
- Domain and DNS management.
- Email and SSL management.
- Backups and server administration.
- cPanel migration tooling.

- GitHub: https://github.com/pkawalya/hosting-panel
- License: MIT
- Maturity: Release candidate

### LPanel

**Best for:** Laravel-based web hosting administration.

- Built with Laravel.
- Virtual host management.
- Linux user management.
- MariaDB/MySQL and PostgreSQL database administration.
- Nginx and Apache support.

- GitHub: https://github.com/Roskus/lpanel
- License: MIT

### Liberu Control Panel

**Best for:** Modular Laravel hosting and infrastructure management.

- Laravel-based architecture.
- Web services and DNS management.
- Email and database administration.
- File management and backups.
- Security and container-related capabilities.

- GitHub: https://github.com/liberusoftware/control-panel-laravel
- License: MIT

## 2. Mature Open-Source cPanel Alternatives

These projects are not necessarily built with Laravel, but provide established hosting administration capabilities.

| Project | Best Use | Technology | Website | GitHub/Repository |
|---|---|---|---|---|
| HestiaCP | All-in-one web hosting, DNS and email | PHP, Bash | https://hestiacp.com/ | https://github.com/hestiacp/hestiacp |
| ISPConfig | Multi-server hosting and reseller environments | PHP | https://www.ispconfig.org/ | https://git.ispconfig.org/ispconfig/ispconfig3 |
| CloudPanel | PHP, Laravel, WordPress and Node.js hosting | PHP | https://www.cloudpanel.io/ | https://github.com/cloudpanel-io/cloudpanel-ce |
| Virtualmin | Traditional hosting administration | Perl, Webmin | https://www.virtualmin.com/ | https://github.com/virtualmin/virtualmin-gpl |

## 3. Recommended MSP/MSSP Architecture

For a hosting and managed services business, separate billing from hosting administration.

```text
                 Customer Portal
                        |
                Billing Platform
                        |
             Paymenter / FOSSBilling
                        |
                Provisioning API
                        |
          +-------------+-------------+
          |             |             |
       Web Hosting   DNS / Email   Databases
          |             |             |
       Linux VMs    Mail Services   MySQL/PostgreSQL
          |
   Hosting Control Panel
   Jabali / HestiaCP / ISPConfig
```

### Component Selection

| Component | Recommended Options |
|---|---|
| Billing and customer accounts | Paymenter or FOSSBilling |
| Hosting control panel | Jabali Panel, HestiaCP or ISPConfig |
| Web application framework | Laravel |
| Admin panel for custom applications | Filament |
| Database | MariaDB or PostgreSQL |
| Provisioning integration | REST APIs or custom Laravel modules |
| Infrastructure | Linux VMs or dedicated servers |

## 4. Production Considerations

Before deploying a hosting panel for customer workloads, verify:

- Tenant and account isolation.
- Privileged server operations and access controls.
- Domain, DNS and email provisioning.
- SSL certificate issuance and renewal.
- Backup and restore functionality.
- Security updates and maintenance.
- Multi-server and reseller support.
- Billing and provisioning API integration.
- Monitoring, logging and incident response.

## Recommendation

1. **Jabali Panel:** Investigate first if Laravel is a firm requirement.
2. **HestiaCP:** Evaluate for an all-in-one hosting environment.
3. **ISPConfig:** Evaluate for multi-server and reseller hosting.
4. **Paymenter:** Use as a potential billing layer, separately from the hosting control panel.

Verify each project's current maintenance status, release maturity, license and feature coverage before deploying it in production.


