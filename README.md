# Подключаем к Synology ИБП без snmp-карты.

Настройка ИБП через snmp (без карты) в Synology.<br>
Для таких же как и я, кто зажал покупать snmp-карту в бесперебойник по цене половины бесперебойника).<br><br>

Итак. Имеется. ИБП PowerCom SRT-1500. Подключен к pve7.4 по usb.<br>
На самом хосте крутится apcupsd в режиме netserver ([Папка с Конфигом хоста](src/pve)).<br>
На этом же хосте (можно на любом другом в сетевой доступности) развернут контейнер Centos 9 stream (нет зависимости от ОС. любая). Для Centos надо дополнительно ставить пакет "bc".<br>
В контейнере крутится apcupsd в режиме слейва.<br>
В этом же контейнере запущен snmpd ([Папка с Конфигами контейнера](src/lxc)).<br>
<br>
Желательно проверить (лучше с третьей машины) работоспособность snmp-демона:<br>
<ul>
  <li>snmpwalk -c public -v2c %addressesSNMPD% .1.3.6.1.4.1.318.1.1.1</li>
  <li>snmpget -c public -v2c %addressesSNMPD% .1.3.6.1.4.1.318.1.1.1</li>
</ul>
где <b>%addressesSNMPD%</b> - ip Контейнера с snmpd.<br>
В первом варианте должно вылететь 22 строки с ответами. Во-втором - одна с названием ИБП.<br>
Если нет каких-либо ошибок, едем дальше.<br>
<br>
Тестировалось на DSM 6.2.2 / DSM 6.2.3<br>
Панель управления -> Оборудование и питание -> ИБП:<br>
  <ul>
    <li>Установить галку "Включить..."</li>
    <li>"Тип сетевого ИБП" = "ИБП SNMP"</li>
    <li>"IP-адрес ИБП SNMP" = ip Контейнера с snmpd.</li>
    <li>"SNMP MIB" = "apcc"</li>
    <li>"Версия SNMP" = "v2c"</li>
    <li>"Сообщество SNMP" = "public"</li>
    <li>Нажать "Применить".</li>
  </ul>
Если появилась "зеленая галка", нажимаем кнопку "Информация об устройстве" и смотрим, чтобы отображаемые параметры были похожи на правду.<br>
<br>
По большому счету, никакой магии в настройке apcupsd и snmpd нет. Всю работу делает apcupsd.sh.<br>
Файл будет редактироваться и унифицироваться для бОльших потенциальных потребителей snmp.<br>
Т.к. мой ИБП не особо родной для apcupsd, на многие OID отдаются заглушки (на основе POWERNET-MIB).<br>
В зависимости от вашего ИБП, apcupsd может отдавать больше полезной информации (хотя synology она не интересна). Следовательно, можно будет расширить apcupsd.sh.<br>
<br>
Удачи в удешевлении обслуживания инфраструктуры).
