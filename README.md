<!-- HavenSMP deployment project -->
<div align="center">

  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:071827,40:0F766E,75:2563EB,100:172554&height=210&section=header&text=HavenSMP&fontSize=58&fontColor=FFFFFF&fontAlignY=37&desc=YOUR%20SERVERS.%20ONE%20CONTROL%20CENTER.&descAlignY=61&descSize=14&animation=fadeIn" alt="HavenSMP banner" />

  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&duration=2600&pause=900&color=67E8F9&center=true&vCenter=true&width=680&lines=HavenSMP+Server+Control;Pterodactyl+Panel+%2B+Wings;Build.+Manage.+Play." alt="Animated HavenSMP tagline" />
  </a>

  <br/><br/>
  ![Panel](https://img.shields.io/badge/Panel-Pterodactyl%201.15.2-0EA5E9?style=for-the-badge)
  ![Wings](https://img.shields.io/badge/Wings-1.13.5-16A34A?style=for-the-badge)
  ![Automation](https://img.shields.io/badge/Deployment-GitHub%20Actions-7C3AED?style=for-the-badge)

  **Your servers. One control center.**
</div>

---

## 🧩 Architecture

```text
                    Browser
                       |
                       v
              Pterodactyl Panel
           Users • Nodes • Server Admin
                       |
                  HTTPS / API
                       |
                       v
               Wings on your VPS
                  Docker Engine
                       |
          +------------+------------+
          |            |            |
        Paper        Purpur       Vanilla
       Minecraft    Minecraft    Minecraft
```

- **Panel** is the web dashboard for managing users, nodes, allocations and game servers.
- **Wings** runs on a Linux node and manages game servers in Docker containers.
- **Eggs** are server templates. The official Panel database seed adds the default Nests and Eggs.

## 🚀 Automated deployment with GitHub Actions

GitHub Actions runs the setup commands, but the services are installed on **your VPS**, not on GitHub's temporary runner.

The installer targets:
- Pterodactyl Panel **v1.15.2** (stable 1.x release)
- NGINX, PHP 8.3, MariaDB, Redis and Composer 2
- HTTPS certificates for the Panel and Wings hostnames
- A **DeepuRana** administrator account
- Default Pterodactyl Nests and Eggs using the official database seed
- Docker Engine and Wings **v1.13.5** binary
- Panel queue worker and scheduler services

Wings is installed but not started until you create its node in Panel and provide the generated node configuration.

## 1. VPS and DNS prerequisites

Use a **fresh KVM VPS** with:

- Ubuntu 24.04 (the installer intentionally supports this OS only)
- Root SSH access, or an SSH user with passwordless sudo
- Working systemd and Docker support
- A public IPv4 address
- At least 2 GB RAM for the Panel and supporting services; allocate additional resources for Minecraft servers
- A domain or subdomains you control

Create two DNS A records pointing to the VPS public IPv4:

| Hostname example | Points to |
|---|---|
| panel.example.com | VPS IPv4 |
| node.example.com | Same VPS IPv4 |

Replace these examples with your own domain. DNS must resolve before the installer requests HTTPS certificates.

**Important:** Run this only on a new VPS. The installer removes Ubuntu's default NGINX site and refuses to overwrite an existing Pterodactyl Panel or Wings configuration. Do not use it on a VPS hosting other websites or services.

## 2. Create an SSH key for GitHub Actions

On your own computer, create a dedicated key pair:

```bash
ssh-keygen -t ed25519 -a 64 -f haven-pterodactyl -C "github-actions-haven"
```

Install the public key file, haven-pterodactyl.pub, in the VPS user's SSH authorized_keys file.

The private key file, haven-pterodactyl, goes into GitHub Actions Secrets. Never commit either key to this repository.

Collect the server's host key from a trusted computer:

```bash
ssh-keyscan -H YOUR_VPS_IP
```

Verify its fingerprint against your VPS provider's console or another trusted source before saving the full output. The workflow uses strict host-key checking and refuses an unpinned host.

For a non-root SSH user, configure passwordless sudo; the workflow uses sudo -n and cannot answer an interactive sudo password prompt.

## 3. Add repository Actions secrets

Open [HavenSMP → Settings → Secrets and variables → Actions](https://github.com/bucketstarrrYT/HavenSMP/settings/secrets/actions) and add these repository secrets:

| Secret | What to put in it |
|---|---|
| HAVEN_VPS_HOST | VPS public IPv4 address or SSH hostname |
| HAVEN_VPS_USER | SSH username, such as root |
| HAVEN_VPS_SSH_PRIVATE_KEY | Dedicated SSH private key |
| HAVEN_VPS_KNOWN_HOSTS | Verified host-key lines from ssh-keyscan -H |
| HAVEN_ADMIN_PASSWORD | Unique Panel password for DeepuRana |

The installer requires an administrator password with at least 12 characters, including uppercase letters, lowercase letters and numbers. Use a password manager to generate it. Do not send it in chat or commit it.

## 4. Run the Panel + Wings installer

1. Open [HavenSMP — Install Pterodactyl](https://github.com/bucketstarrrYT/HavenSMP/actions/workflows/install-haven-pterodactyl.yml).
2. Select **Run workflow**.
3. Enter your Panel DNS name (for example, panel.example.com), Wings DNS name (for example, node.example.com), contact email, administrator email and SSH port (usually 22).
4. Click **Run workflow** and watch the logs.

The workflow connects to your VPS over SSH and runs the installer script in this repository. It does not turn the temporary GitHub runner into your permanent host.

## 5. Sign in and create the Wings node

After the first workflow succeeds:

1. Visit your Panel URL using HTTPS.
2. Sign in with username **DeepuRana**, the admin email entered in the workflow, and the password stored in HAVEN_ADMIN_PASSWORD.
3. Open **Admin → Nodes → Create New**.
4. Set the node FQDN to your Wings DNS name.
5. Enable SSL for the daemon, and use daemon port 8080 and SFTP port 2022.
6. Create the node and add allocations using the VPS public IPv4 address. Do not use 127.0.0.1 for player-facing allocations.
7. Open the node's **Configuration** tab and copy the complete generated config.yml.

## 6. Configure and start Wings

The generated node configuration contains credentials and tokens. Treat it as a password.

1. Return to [Actions Secrets](https://github.com/bucketstarrrYT/HavenSMP/settings/secrets/actions).
2. Add a secret named **HAVEN_WINGS_CONFIG**.
3. Paste the complete generated node configuration YAML into that secret. Do not put it in README, an issue, a commit or a chat message.
4. Open [Configure HavenSMP Wings](https://github.com/bucketstarrrYT/HavenSMP/actions/workflows/configure-haven-wings.yml).
5. Click **Run workflow**.

The workflow writes the config to the Wings configuration folder with restrictive permissions and starts the Wings service. Return to Panel and confirm the node appears connected.

## 7. Create Minecraft servers using Eggs

After Wings is connected and allocations exist:

1. Open **Admin → Servers → Create New**.
2. Choose the node and an available allocation.
3. Select a seeded Minecraft Egg, for example Paper or Vanilla.
4. Set memory, disk, CPU limits and startup variables.
5. Create the server and open its console.

Default Eggs are seeded into the Panel database during installation. The workflow does not create game servers automatically.

## 🌐 Firewall ports

Allow these ports in both the VPS firewall and the hosting provider firewall/security group:

| Port | Protocol | Purpose |
|---|---|---|
| 22 (or your SSH port) | TCP | SSH deployment access |
| 80 | TCP | HTTP and Let's Encrypt validation |
| 443 | TCP | HTTPS Panel |
| 8080 | TCP | Wings API, console and file traffic |
| 2022 | TCP | Wings SFTP |
| Game allocations | TCP/UDP as required | Player connections |

Do not expose MariaDB or Redis publicly.

## 🔐 Access model

| Account | Intended access |
|---|---|
| **DeepuRana** | Panel administrator: manage users, nodes, allocations and create/delete servers |
| Other users | Only the servers and permissions assigned to them |

Enable two-factor authentication after first login. Keep the administrator password and node configuration private.

## ⚠️ Important notes

- The installer configures mail delivery as log initially. SMTP is **not** configured; password-reset and notification emails will not be delivered until you configure a real mail provider.
- Back up the Panel environment file securely. Losing the Panel APP_KEY makes encrypted Panel data unrecoverable.
- Back up the Panel database and game-server data in /var/lib/pterodactyl.
- Never publish the VPS SSH private key, administrator password, Wings config, database credentials, node tokens or Panel environment file.
- If the workflow fails after installing packages, inspect the Actions log and VPS before retrying. The installer is not an in-place upgrade or migration tool.

## 🧰 Service checks

After connecting to the VPS over SSH:

```bash
systemctl status nginx php8.3-fpm mariadb redis-server pteroq docker
systemctl status wings
docker info
```

Wings remains inactive until its generated node configuration is applied.

## 📚 Official links

- [Pterodactyl stable 1.x documentation](https://docs.pterodactyl.io/v1)
- [Panel installation guide](https://docs.pterodactyl.io/v1/panel/getting-started)
- [Wings installation guide](https://docs.pterodactyl.io/v1/wings/installing)
- [Panel releases](https://github.com/pterodactyl/panel/releases)
- [Wings releases](https://github.com/pterodactyl/wings/releases)
- [Default Egg catalog](https://eggs.pterodactyl.io/)

---

<div align="center">

  **HavenSMP — your servers, your community, your control.**

  <a href="https://github.com/bucketstarrrYT">
    <img src="https://img.shields.io/badge/Owner-DeepuRana-181717?style=for-the-badge&logo=github&logoColor=white" alt="DeepuRana GitHub profile" />
  </a>

</div>
