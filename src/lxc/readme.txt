Папка с конфигами apcupsd и snmpd для ВИРТУАЛКИ (centos 9 stream).
Виртуалка и Хост в одной сети.

1. Устанавливаем apcupsd:
	dnf install epel-release epel-next-release
	dnf install apcupsd libusbx bc
	
2. Редактируем файл /etc/apcupsd/apcupsd.conf из Гита:
	для поля "DEVICE" изменить "ipToHost" на реальный айпишник Хоста, к которому подключен ИБП

3. Заменяем на конфиг и ребутим виртуалку.

4. Проверяем, что связь с ИБП установлена (STATUS   : ONLINE SLAVE):
	apcaccess status 

5. Если ок:
	systemctl enable apcupsd
	
6. Ставим snmpd:
	dnf install net-snmp
	
7. Редактируем файл /etc/snmpd/snmpd.conf из Гита:
	syslocation "Имя виртуалки"
	syscontact "почта, если нужно"
	
8. Копируем с заменой ВСЕ файлы из Гита на Виртуалку. На файл /etc/snmpd/apcupsd.sh выставить права 0644.

9. systemctl restart snmpd

10. Проверяем, что летят ответы в формате snmp:
	snmpwalk -c public -v2c localhost .1.3.6.1.4.1.318.1.1.1
	
10.1. 	Также желательно проверить доступность snmpd с другой машины в той же сети.
		тогда localhost из п.10 заменить на реальный IP Виртуалки.
		Вывод может отличаться представлением формы OID, это не страшно. Главное, чтобы без ошибок.

11. Когда все ок:
	systemctl enable snmpd
	
Тут все. Идем настраивать Synology