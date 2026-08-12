## Minecraft Server Seeker scripts for nmap

#### Minecraft Java Server Seeker:
* Full Scan:
```
nmap -Pn -p- --script=java.nse --script-args "java.protocol=776" 192.168.1.1/24
```
* Quick Scan:
```
nmap -Pn -p 25565 --script=java.nse --script-args "java.protocol=776" 192.168.1.1/24
```
* Script arguments are optional
