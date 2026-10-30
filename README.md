## NMAP NSE Scripts

#### mc-server-seeker:
* Minecraft Java Server Seeker

```
nmap -Pn -p 25565 --script=mc-server-seeker.nse 192.168.1.1/24 | grep Log4Shell
```

#### contacts-scraper:
* Web Application Email and Password Scraper
