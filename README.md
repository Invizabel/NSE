## Minecraft Server Seeker scripts for nmap

#### Minecraft Java Server Seeker:
* Full Scan (With Args):
```
nmap -Pn -p- --script=java.nse --script-args "java.protocol=776" 192.168.1.1/24
```
* Quick Scan (With Args):
```
nmap -Pn -p 25565 --script=java.nse --script-args "java.protocol=776" 192.168.1.1/24
```
* Full Scan (Without Args):
```
nmap -Pn -p- --script=java.nse 192.168.1.1/24
```
* Quick Scan (Without Args):
```
nmap -Pn -p 25565 --script=java.nse 192.168.1.1/24
```

#### Notes:
* Script arguments are optional
