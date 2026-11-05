## NMAP NSE Scripts

#### mc-server-seeker:
* Minecraft Java Server Seeker

```
nmap -p- -v --script=mc-server-seeker.nse 192.168.1.1/24 > out.txt
cat out.txt | grep Log4Shell
```

#### web-seeker:
* Web Application Seeker

```
nmap -p- -v --script=web-seeker.nse 192.168.1.1/24 > out.txt
cat out.txt | grep Status
```

#### contacts-scraper:
* Web Application Email and Password Scraper
