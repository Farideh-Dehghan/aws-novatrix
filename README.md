
# AWS – Novatrix AB

**Namn:** Farideh Dehghan

**Kurs:** Amazon Web Services

## Uppgift 1 (v42) – Compute och kom igång
Provisionering av en EC2-instans med Amazon Linux och driftsättning av en enkel webbserver för Novatrix AB.

## Uppgift 2 (v43) – IAM och identitet
Användare, grupper, policies och roller för Novatrix AB enligt least privilege, inklusive en IAM-roll som ger EC2-instansen läsbehörighet till en S3-bucket.
## Uppgift 3 (v44) – Nätverk och säkerhet
Ett eget VPC för Novatrix AB med publikt och privat subnät, route tables och internet gateway. Defense in depth med security groups och NACL:er. Webbservern ligger i det publika subnätet och det privata subnätet är förberett för databasen.
## Uppgift 4 (v45) – Storage och databas


WordPress för Novatrix AB med hanterad databas, delad fillagring och backup till S3.

**Arkitektur**
- **EC2** (ec2-novatrix-web-v44) i publikt subnät: Apache, PHP 8.5 och WordPress
- **Amazon RDS** (novatrix-db): MariaDB 11.8, db.t4g.micro, i privata subnät, ingen publik åtkomst, backup 1 dag
- **Amazon EFS** (novatrix-efs): monterad på /var/www/html med TLS, mount targets i båda privata subnäten
- **Amazon S3** (novatrix-assets-697520883832): backuper under prefixet backups/

**Säkerhet**
- novatrix-sg-db släpper bara in MySQL (3306) från novatrix-sg-web
- novatrix-sg-efs släpper bara in NFS (2049) från novatrix-sg-web
- RDS kräver krypterad anslutning (require_secure_transport), WordPress ansluter med SSL
- IAM-rollen ec2-novatrix-s3-read har fått en inline policy (novatrix-backup-write) som bara tillåter s3:PutObject på backups/* – least privilege
- Databaslösenordet ligger i /root/.my.cnf (chmod 600), inte i skriptet

**Backup**
- Skriptet /usr/local/bin/novatrix-backup.sh gör mysqldump av databasen och tar av wp-content, och laddar upp båda till S3
- Cron kör skriptet varje natt kl. 02:00
- Lifecycle-regeln novatrix-backup-14d tar bort backuper under backups/ efter 14 dagar
## Uppgift 5 (v46) – IaC med CloudFormation

Hela WordPress-stacken för Novatrix AB är skriven som kod i tre CloudFormation-templates. Stackarna läser varandras värden med Export och !ImportValue.

| Template | Stack | Innehåll |
|---|---|---|
| natverk.yaml | novatrix46-natverk | VPC, ett publikt och två privata subnät, internet gateway, route table, NACL, security groups för webb, databas och EFS |
| data.yaml | novatrix46-data | RDS MariaDB (privat, krypterad), lösenord genererat i Secrets Manager, EFS med mount targets i två AZ |
| webb.yaml | novatrix46-webb | IAM-roll och instance profile, EC2 som installerar Apache, PHP och WordPress och monterar EFS via user data |

**Parametrar:** Prefix (namn på alla resurser), MyIp (SSH bara från min dator), DbInstanceClass, InstanceType, KeyName, DataBucket och BackupBucket. Inga lösenord finns i repot.

### Återskapa stacken från repot
1. Klona repot: `git clone https://github.com/Farideh-Dehghan/aws-novatrix.git`
2. Validera: `aws cloudformation validate-template --template-body file://natverk.yaml`
3. Skapa stackarna i ordning (CloudFormation → Create stack → Upload a template file):
   - `natverk.yaml` som `novatrix46-natverk`, ange MyIp
   - `data.yaml` som `novatrix46-data` (tar ca 10 minuter för RDS)
   - `webb.yaml` som `novatrix46-webb`, ange KeyName och buckets, kryssa i IAM-capability
4. Öppna WebUrl från webb-stackens Outputs. Database Host är DbEndpoint från data-stacken, lösenordet hämtas i Secrets Manager.
5. Riv i omvänd ordning: webb, data, natverk.

### Versionshantering
Ändringen "v46: add Course tag to VPC" lade till en tagg i natverk.yaml. Stacken uppdaterades med Update stack, och change set visade en enda ändring: Modify på Vpc med Replacement False. Historiken i Git visar vem som ändrade vad och när. Det gör att man kan granska ändringar innan de körs, gå tillbaka till en tidigare version om något går fel, och arbeta flera personer i samma kod utan manuella klick i konsolen.


## Uppgift 6 (v47) – Skalbarhet och tillgänglighet

WordPress-stacken körs nu bakom en Application Load Balancer med en Auto Scaling-grupp över två tillgänglighetszoner. Allt är byggt som kod.

| Fil | Stack | Innehåll |
|---|---|---|
| natverk.yaml | novatrix46-natverk | Uppdaterad: andra publika subnätet (public-b, 10.0.3.0/24) och security group för ALB |
| skala.yaml | novatrix46-skala | ALB, target group med health check på /wp-login.php, launch template, Auto Scaling-grupp (min 2, max 4) och target tracking på 50 % CPU |
| lasttest.sh | – | Belastar CPU i 15 minuter för att testa skalningen |

Nya servrar konfigurerar sig själva vid start: de monterar EFS, hämtar databaslösenordet från Secrets Manager och skriver wp-config.php. Inga lösenord finns i repot.

### Test av tillgänglighet
En server terminerades manuellt. Sajten svarade hela tiden via den andra servern, och Auto Scaling startade en ersättare inom en sekund ("unhealthy instance needing to be replaced").

### Test av skalning
lasttest.sh kördes på båda servrarna. AlarmHigh ökade gruppen från 2 till 3 och sedan 4 servrar. När lasten tog slut minskade AlarmLow gruppen tillbaka till 2.

### Kostnad (AWS Pricing Calculator, eu-north-1, On-Demand, utan Free Tier)
| | Normal last (2 servrar) | Utskalat (4 servrar) |
|---|---|---|
| EC2 t3.micro | 17,11 USD | 34,22 USD |
| Application Load Balancer | 17,49 USD | 17,49 USD |
| RDS MariaDB db.t3.micro, Single-AZ, 20 GB | 33,06 USD | 33,06 USD |
| EFS 1 GB | 0,30 USD | 0,30 USD |
| **Per månad** | **67,96 USD** | **85,07 USD** |

Skalningen påverkar bara EC2-delen, så kostnaden ökar ungefär 25 % vid full last. Med Savings Plans eller reserverade instanser skulle EC2 och RDS bli upp till cirka 60–70 % billigare för en fast baslast.
