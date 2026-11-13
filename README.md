
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

