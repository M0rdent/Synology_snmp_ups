Папка с конфигом apcupsd для ХОСТА, к которому ИБП подключен напрямую по usb.

1. Проверяем, что хост видит наш ИБП:
	lsusb
	
2. Устанавливаем apcupsd:
	apt update
	apt install apcupsd
	
3. Редактируем файл /etc/apcupsd/apcupsd.conf из Гита под себя

4. Заменяем на хосте

5. systemctl restart apcupsd

6. Проверяем, что связь с ИБП установлена:
	apcaccess status
	
	6.1. Если ошибка, перезапустить хост и проверить снова.
	
7. Если все ок:
	systemctl enable apcupsd
	
С хостом закончили. Можно прикрутить оповещения на e-mail.