#!/bin/sh -f
# ver. 1.0 from 09.06.2023
# by M0rdent

# Проверим, что apcupsd работает. Иначе выход
apcaccess > /dev/null 2>&1 || exit 0
# Переменные
PLACE=".1.3.6.1.4.1.318.1.1.1"
ORIG=$2		# Orig request OID
P=1350		# Мощность бесперебойника для рассчета силы тока

if [ "$1" = "-s" ]; then # Если пришел запрос на "изменение" OID - отправим в лог
	echo $* >> /tmp/passtest.log
	exit 0
fi

# Работаем с запросом
# Внимание! Kostyl! для многих ответов стоит "умножение на 10". 
# Сделано специально, т.к. Synology к полученному ответу автоматом смещает "точку" влево
case $ORIG in
	$PLACE | $PLACE.0 | $PLACE.1. | $PLACE.1.1.0* | $PLACE.1.1.1.0) # Название UPS
		RETTYPE="string";
		RET=$(apcaccess -u -p UPSNAME);
		NEXT=$PLACE.2.1.1.0 ;;
	$PLACE.2.1.1.0) # Статус батареи. Мой ИБП не отдает нативно. Будем высчитывать.
		RETTYPE="Gauge32";
		if (( $(printf "%.f" $(apcaccess -u -p BCHARGE)) > 30 )); then
			RET=2 # Заряжена
		else
			RET=3 # Разряжена
		fi
		NEXT=$PLACE.2.2.1.0 ;;		
	$PLACE.2.2.1.0 | $PLACE.2.3.1.0) # Процент заряда.
		RETTYPE="Gauge32";
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p BCHARGE)) * 10)); 
		NEXT=$PLACE.2.2.2.0 ;;	
	$PLACE.2.2.2.0 | $PLACE.2.3.2.0) # Текущая внутренняя температура
		RETTYPE="Gauge32";
		RET=$(echo "scale=2; ($(apcaccess -u -p ITEMP) + 273.15) * 10" | bc -l);
		NEXT=$PLACE.2.2.3.0 ;;
	$PLACE.2.2.3.0) # Время работы от батареи
		RETTYPE="Timeticks";
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p TIMELEFT)) * 6000)); 
		NEXT=$PLACE.2.2.7.0 ;;	
	$PLACE.2.2.4*) # Нужна ли замена батарей (заглушка). На эту строку никто не ссылается. Только прямой запрос
		RETTYPE="Gauge32";
		RET=1; 
		NEXT=$PLACE.2.2.7.0 ;;
	$PLACE.2.2.5.0 | $PLACE.2.2.6.0) # Количество внешних аккумов (заглушка). На эту строку никто не ссылается. Только прямой запрос
		RETTYPE="Gauge32";
		RET=0; 
		NEXT=$PLACE.2.2.7.0 ;;	
	$PLACE.2.2.7.0) # Номинальное напряжение батареи
		RETTYPE="Gauge32";
		RET=$(apcaccess -u -p NOMBATTV); 
		NEXT=$PLACE.2.2.8.0 ;;
	$PLACE.2.2.8.0 | $PLACE.2.3.4.0) # Фактическое напряжение
		RETTYPE="Gauge32";
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p OUTPUTV)) * 10));
		NEXT=$PLACE.2.2.9.0 ;;
	$PLACE.2.2.9.0) # Напряжение батареи
		RETTYPE="Gauge32";
		RET=$(apcaccess -u -p BATTV); 
		NEXT=$PLACE.2.3.5.0 ;;
	$PLACE.2.3.5.0) # Ток батареи в амперах
		RETTYPE="Gauge32";
		B=$(printf "%.f" $(apcaccess -u -p BATTV));
		C=$(printf "%.f" $(apcaccess -u -p BCHARGE));
		RET=$(echo "scale=2; $P / $B * $C / 10" | bc -l);
		NEXT=$PLACE.2.3.6.0 ;;
	$PLACE.2.3.6.0) # Общий постоянный ток
		RETTYPE="Gauge32";
		L=$(printf "%.f" $(apcaccess -u -p LINEV));
		RET=$(echo "scale=2; $P / $L * 10" | bc -l);
		NEXT=$PLACE.3.2.1.0 ;;
	$PLACE.3.*) # Входящее напряжение
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p LINEV)) * 10));
		NEXT=$PLACE.3.3.4.0;
		RETTYPE="Gauge32";
		if [ $ORIG = $PLACE.3.3.4.0 ]; then # Входящая частота
			RET=$(($(printf "%.*f" 0 $(apcaccess -u -p LINEFREQ)) * 10));
			NEXT=$PLACE.4.1.1.0;
		fi;
		if [ $ORIG = $PLACE.3.2.5.0 ]; then # Причина переключения на аккумулятор (Заглушка)
			RET=1;
			NEXT=$PLACE.4.1.1.0;
		fi ;;		
	$PLACE.4.1.1* | $PLACE.4.1.3*) # Статус
		RETTYPE="Gauge32";
		S=$(apcaccess -u -p STATUS);
		case ${S^^} in
			UNKNOWN*) RET=1 ;;
			ONLINE*) RET=2 ;;
			ONBATT*) RET=3 ;;
			ONSMARTBOOST*) RET=4 ;;
			TIMED*) RET=5 ;;
			SOFTWA*) RET=6 ;;
			OFF*) RET=7 ;;
			REBOOT*) RET=8 ;;
			SWITCHED*) RET=9 ;;
			HARDWARE*) RET=10 ;;
			SLEEPING*) RET=11 ;;
			ONSMARTTRIM*) RET=12 ;;
			*) RET=1 ;;
		esac ;
		NEXT=$PLACE.4.2.1.0 ;;
	$PLACE.4.2.1.0 | $PLACE.4.3.1.0) # Выходное напряжение
		RETTYPE="Gauge32";
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p OUTPUTV)) * 10));
		NEXT=$PLACE.4.2.2.0;;
	$PLACE.4.2.2.0 | $PLACE.4.3.2.0) # Входная и Выходная частота
		RETTYPE="Gauge32";
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p LINEFREQ)) * 10));
		NEXT=$PLACE.4.2.3.0 ;;		
	$PLACE.4.2.3.0 | $PLACE.4.3.3.0) # Текущая нагрузка
		RETTYPE="Gauge32";
		RET=$(($(printf "%.*f" 0 $(apcaccess -u -p LOADPCT)) * 10));
		NEXT=$PLACE.4.2.4.0 ;;
	$PLACE.4.2.* | $PLACE.4.3.* |$PLACE.5*|$PLACE.6*|$PLACE.7.0*|$PLACE.7.1*|$PLACE.7.2.0*|$PLACE.7.2.1*|$PLACE.7.2.2*) # Ток, подтребляемый нагрузкой
		RETTYPE="Gauge32";
		O=$(printf "%.f" $(apcaccess -u -p OUTPUTV));
		L=$(printf "%.f" $(apcaccess -u -p LOADPCT));
		RET=$(echo "scale=2; $P / $O * $L / 10" | bc -l);
		NEXT=$PLACE.7.2.3.0 ;;
	$PLACE.7.2.3.0 | $PLACE.7.2.4.0 | $PLACE.7.2.5.0) # Результат последнего теста
		RETTYPE="Gauge32";
		T=$(apcaccess -u -p SELFTEST);
		if [ "$T" != "OK" ]; then RET=2; else RET=1; fi
		NEXT=$PLACE.7.2.6.0 ;;
	$PLACE.7.2.6.0) # Результат калибровки (заглушка)
		RETTYPE="Gauge32";
		RET=1;
		NEXT=$PLACE.8.1.0 ;;
	$PLACE.7* | $PLACE.8.0* | $PLACE.8.1.0) # Статус соединения. Если больше двух минут с момента обновления - соединение потеряно
		RETTYPE="Gauge32";
		D=$(date +%s -d "$(apcaccess -u -p DATE)");
		if (( $[ ($(date +%s) - $D) / 60 ] > 2 )); then RET=2; else RET=1; fi
		NEXT=$PLACE.17.1.0 ;;
	$PLACE.9.1* | $PLACE.9.2* | $PLACE.9.3*) # Левые параметры, летят от synology (заглушка)
		RETTYPE="Integer32";
		RET=-1;
		NEXT=$PLACE.17.1.0 ;;
	$PLACE.17.1*) # Кол-во переходов на аккум
		RETTYPE="Gauge32";
		RET=$(apcaccess -u -p NUMXFERS);
		NEXT=$PLACE.17.2.0 ;;
	$PLACE.17.2*) # время работы от аккума
		RETTYPE="Gauge32";
		RET=$(apcaccess -u -p TONBATT);
		NEXT=$PLACE.17.3.0 ;;
	$PLACE.17.3*) # время работы от аккума всего
		RETTYPE="Gauge32";
		RET=$(apcaccess -u -p CUMONBATT);
		NEXT="" ;;	
esac
if [ "$1" = "-n" ]; then ORIG=$NEXT; fi
echo -e "$ORIG\n$RETTYPE\n$RET"
# Остался затык с 5* - 7* OID. Надо разобраться.
exit 0