#power key


finddev() {
	cfgpath=`find  /sys/devices/platform/ -name "ttyUSB*" | grep "2-1\.3\/" | grep "1\.3\.1:1\.2" | grep -v "tty\/"`
	#echo $cfgpath
	dev="$(basename $cfgpath)"
	echo $dev
}

#make pppcmd

while [ 1 ]; do
	logger "==========> power off/on BG96"
	/usr/bin/bg96_powerup.sh off
	sleep 1
	/usr/bin/bg96_powerup.sh on
        sleep 15
        num=`dmesg | grep 2c7c |awk -F "usb "  '{print $2}' |awk -F: {'print $1'}`
        echo $num
        if [ ! "$num" == "" ]; then
            path=`find  /sys/devices/platform/ -name "ttyUSB*" | grep -v "tty\/" | grep "$num" | tail -2 | grep -m 1 "USB"`
            echo $path

            dev="$(basename $path)"
            echo $dev

            if [ ! "$dev" == "" ]; then
                sed -i "s/\/dev\/.* 115200/\/dev\/$dev 115200/g"  /etc/ppp/peers/quectel-ppp
                sleep 1
            fi
        fi

	dev=`grep 115200 /etc/ppp/peers/quectel-ppp | cut -d ' ' -f1 | cut -b 6-`
	logger "dev ->" $dev

	while [ 1 ]; do
		if [ -e /dev/$dev ]; then
			sleep 1
			break
		fi
		sleep 1
	done

	yyy="20"
	while [ $yyy -gt 0 ]; do
		/usr/bin/pppcmd /dev/$dev 'AT+COPS?'
		/usr/bin/pppcmd /dev/$dev 'AT+CEREG?'
		/usr/bin/pppcmd /dev/$dev 'AT+CGREG?'
		/usr/bin/pppcmd /dev/$dev 'AT+CREG?'
		/usr/bin/pppcmd /dev/$dev 'AT+CPIN?'
		/usr/bin/pppcmd /dev/$dev 'AT+CSQ'
		regm=`/usr/bin/pppcmd /dev/$dev 'AT+CREG?' | grep 'CREG: 0,1' | wc -l`
		[ "$regm" == "1" ] && {
			logger reg ok
			break;
		}
		regm=`/usr/bin/pppcmd /dev/$dev 'AT+CREG?' | grep 'CREG: 0,5' | wc -l`
		[ "$regm" == "1" ] && {
			logger reg ok
			break;
		}
		sleep 3
		yyy=$((yyy-1))
	done

	logger "get 4g at device: $dev"

	pppd call quectel-ppp
	sleep 1
done


