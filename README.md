<!--
  HavenSMP | Game server control center
  Brand/documentation page for a planned Pterodactyl deployment.
-->

<div align="center">

  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:071827,40:0F766E,75:2563EB,100:172554&height=220&section=header&text=HavenSMP&fontSize=60&fontColor=FFFFFF&fontAlignY=37&desc=YOUR%20SERVERS.%20ONE%20CONTROL%20CENTER.&descAlignY=61&descSize=14&animation=fadeIn" alt="HavenSMP banner" />

  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&duration=2600&pause=900&color=67E8F9&center=true&vCenter=true&width=680&lines=HavenSMP+Server+Control;Powered+by+Pterodactyl+Panel+%2B+Wings;Build.+Manage.+Play." alt="Animated HavenSMP tagline" />
  </a>

  <br/><br/>

  ![Platform](https://img.shields.io/badge/Platform-Pterodactyl-0EA5E9?style=for-the-badge)
  ![Runtime](https://img.shields.io/badge/Node-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
  ![Status](https://img.shields.io/badge/Deployment-Not%20Connected%20Yet-F59E0B?style=for-the-badge)

  <br/>

  **A central place to manage HavenSMP game servers.**

  <sub>Designed around Pterodactyl Panel and Wings. Actual hosting deployment is still required.</sub>

</div>

---

## 🌐 What is HavenSMP?

HavenSMP is the project space for a game-server control setup. The planned hosting stack uses **Pterodactyl Panel** for the web interface and **Wings** to run game servers in isolated Docker containers.

The goal is to manage server instances from one browser dashboard instead of manually handling each server from a terminal.

## 🧩 How the system fits together

```text
                 Your browser
                      |
                      v
             Pterodactyl Panel
          Users • Nodes • Servers
                      |
                secure API
                      |
                      v
                Wings daemon
                 on a node
                      |
                      v
              Docker containers
                /     |     \
             SMP    Lobby  Other
            server  server servers
```

- **Panel** is the web dashboard used to manage users, nodes, and game servers.
- **Wings** is the Linux service installed on each node. It manages Docker containers and runs the game servers.
- **Nodes** are the machines that provide CPU, memory, disk, and network allocations to those servers.

> **Important:** Wings is not the web panel. It is the node daemon that connects to the Panel and runs the game servers.

## 🛡️ Planned management access

The intended owner account is **DeepuRana**.

Once the Panel is deployed, the owner account should be created as a Pterodactyl administrator. An administrator can use the admin area to manage nodes and create or remove server instances.

| Access | Intended capability |
|---|---|
| **DeepuRana — Administrator** | Manage users, nodes, allocations, and create/remove game servers |
| Server user | Access only the servers assigned to that account and the permissions granted for each server |

Administrator access is powerful. Keep the account protected with a unique password and two-factor authentication where available. Never publish Application API keys, Wings tokens, passwords, or node configuration secrets in this repository.

## ✅ Deployment checklist

This repository currently contains the project documentation only. No live Panel URL, hosting node, Wings daemon, or administrator login has been configured through this repository.

- [ ] Provision a Docker-capable Linux VPS or dedicated server
- [ ] Install the Pterodactyl Panel and configure HTTPS
- [ ] Create the HavenSMP administrator account
- [ ] Register a node in the Panel
- [ ] Install and connect Wings to that node
- [ ] Configure public allocations and required firewall ports
- [ ] Test creating, starting, stopping, and deleting a test server

## 🖥️ Hosting requirements

For a production setup, use a supported Linux host with root access and Docker support. The Pterodactyl stable 1.x installation guide lists supported Ubuntu and Debian releases; check the current official requirements before provisioning.

| Component | Purpose |
|---|---|
| Linux VPS / dedicated host | Runs the Panel and/or Wings node |
| Docker | Isolates each game server |
| Pterodactyl Panel | Web dashboard and server management |
| Wings | Runs server containers on each node |
| Domain + HTTPS | Secure access to the Panel and node endpoints |

### Network ports

Default Pterodactyl ports include:

| Port | Used for |
|---|---|
| TCP 80 / 443 | Panel website (HTTP / HTTPS) |
| TCP 8080 | Wings API, console and file transfers |
| TCP 2022 | Wings SFTP |
| Allocated game ports | Player connections to each game server |

Only expose the ports you actually use, and restrict administrative access appropriately. Game-server allocations must also be opened in the host and provider firewalls.

## 📚 Official documentation

- [Pterodactyl — How it works](https://docs.pterodactyl.io/v1/project/how-it-works)
- [Panel installation guide](https://docs.pterodactyl.io/v1/panel/getting-started)
- [Wings installation guide](https://docs.pterodactyl.io/v1/wings/installing)
- [Creating a node](https://docs.pterodactyl.io/v1/guides/configuration/add-node)

The official documentation currently identifies Pterodactyl 1.x as the stable release line and 2.0 as beta. Use the release line appropriate for your deployment and check the documentation before upgrading.

## 👑 Project owner

<div align="center">

  <a href="https://github.com/bucketstarrrYT">
    <img src="https://img.shields.io/badge/Owner-DeepuRana-181717?style=for-the-badge&logo=github&logoColor=white" alt="DeepuRana GitHub profile" />
  </a>

  <br/><br/>

  **HavenSMP — your servers, your community, your control.**

  <sub>Project documentation · Deployment pending</sub>

</div>
